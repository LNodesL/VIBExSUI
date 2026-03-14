#!/usr/bin/env node
/**
 * Programmatic deploy: build Move package and publish via @mysten/sui.
 * Env: SUI_NETWORK (default testnet), SUI_RPC_URL (optional override),
 *      SUI_PRIVATE_KEY (base64) or SUI_KEYSTORE_PATH (path to sui keystore).
 */
import { execSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = join(__dirname, "..");
const PKG_DIR = join(REPO_ROOT, "move", "vibex");
const CONFIG_PATH = join(REPO_ROOT, "config", "networks.json");

function getRpcUrl() {
  const url = process.env.SUI_RPC_URL;
  if (url) return url;
  const network = process.env.SUI_NETWORK || "testnet";
  const config = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
  const resolved = config[network];
  if (!resolved) throw new Error(`Unknown SUI_NETWORK: ${network}. Use testnet, mainnet, or devnet.`);
  return resolved;
}

async function getKeypair() {
  const keyB64 = process.env.SUI_PRIVATE_KEY;
  if (keyB64) {
    const { Ed25519Keypair } = await import("@mysten/sui/keypairs/ed25519");
    const bytes = Buffer.from(keyB64, "base64");
    return Ed25519Keypair.fromSecretKey(bytes);
  }
  const keystorePath = process.env.SUI_KEYSTORE_PATH?.replace(/^~/, process.env.HOME || "") ||
    join(process.env.HOME || "", ".sui", "sui_config", "sui.keystore");
  try {
    const content = readFileSync(keystorePath, "utf8");
    const entries = JSON.parse(content);
    if (!Array.isArray(entries) || entries.length === 0) throw new Error("Empty keystore");
    const { decodeSuiPrivateKey } = await import("@mysten/sui/cryptography");
    const { keypair } = decodeSuiPrivateKey(entries[0]);
    return keypair;
  } catch (e) {
    throw new Error(
      `No signer: set SUI_PRIVATE_KEY (base64) or SUI_KEYSTORE_PATH. ${e.message}`
    );
  }
}

async function buildBytecode() {
  const cmd = "sui move build --dump-bytecode-as-base64 --ignore-chain";
  const out = execSync(cmd, { cwd: PKG_DIR, encoding: "utf8", maxBuffer: 10 * 1024 * 1024 });
  const line = out.trim().split("\n").filter(Boolean).pop();
  if (!line) throw new Error("No JSON output from sui move build");
  return JSON.parse(line);
}

async function main() {
  const rpcUrl = getRpcUrl();
  const keypair = await getKeypair();
  console.log("Building...");
  const { modules, dependencies } = await buildBytecode();
  if (!Array.isArray(modules) || !Array.isArray(dependencies)) {
    throw new Error("Build output must have 'modules' and 'dependencies' arrays");
  }

  const { SuiJsonRpcClient } = await import("@mysten/sui/jsonRpc");
  const { Transaction } = await import("@mysten/sui/transactions");

  const client = new SuiJsonRpcClient({ url: rpcUrl });
  const tx = new Transaction();
  tx.setSender(keypair.getPublicKey().toSuiAddress());
  tx.setGasBudget(100_000_000);

  const [upgradeCap] = tx.publish({ modules, dependencies });
  tx.transferObjects([upgradeCap], keypair.getPublicKey().toSuiAddress());

  console.log("Signing and publishing...");
  const result = await client.signAndExecuteTransaction({
    signer: keypair,
    transaction: tx,
    options: { showEffects: true },
  });

  if (result.$kind === "FailedTransaction") {
    throw new Error(`Publish failed: ${result.FailedTransaction.status?.error?.message ?? "unknown"}`);
  }
  const digest = result.Transaction?.digest;
  console.log("Published. Digest:", digest);
  await client.waitForTransaction({ digest });
  console.log("Done.");
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
