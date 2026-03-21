# VIBExSUI

SUI Move contract dev kit: develop, test, and deploy Move packages on **testnet** (MVP default) or **mainnet** with a single env swap. This repo is a starter for general contract development on [Sui](https://sui.io).

## Prerequisites

- **Sui CLI** – [Install guide](https://docs.sui.io/guides/developer/getting-started/sui-install) (binaries, `cargo`, or [suiup](https://github.com/MystenLabs/suiup)).
- **Rust** (if installing from source) – 1.70+.
- A Sui address and testnet SUI for deployment (see below).

## Quick start (testnet MVP)

1. **Install Sui** (if needed):
   ```bash
   # Option: binary release or
   cargo install --locked --git https://github.com/MystenLabs/sui.git --branch testnet sui --features tracing
   ```

2. **Configure the client** (first time):
   ```bash
   sui client
   ```
   If prompted, create config and choose **testnet**. Or add testnet explicitly:
   ```bash
   sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
   sui client switch --env testnet
   ```

   You may not need to create a new env if testnet already exists!

3. **Get testnet SUI**:
   ```bash
   sui client faucet
   ```

   Verify online and receive free testnet SUI.

4. **Build and test** (from repo root):
   ```bash
   npm run build
   npm run test
   ```

5. **Publish to testnet**:
   ```bash
   npm run publish
   ```
   Or use the deploy script (respects `SUI_NETWORK`):
   ```bash
   SUI_NETWORK=testnet ./scripts/deploy.sh
   ```

NOTE: DEPENDING ON SUI CLI VERSION, YOUR PUBLISH SCRIPT MAY DIFFER IN PACKAGE.JSON 
Newer:
```
 "publish": "sui client publish contract --gas-budget 100000000",
 "publish:mainnet": "sui client --client.env mainnet publish contract --gas-budget 100000000",
 ```
Older:
```
publish": "sui client publish --path contract --gas-budget 100000000",
"publish:mainnet": "sui client publish --path contract --gas-budget 100000000 --env mainnet",
```

## Verify setup

- Active env: `sui client active-env` (should be `testnet` for MVP).
- List envs: `sui client envs`.
- Check balance: `sui client balance`.
- Confirm RPC: `sui client gas` (should succeed if the endpoint is reachable).

## Deploying to mainnet

Same codebase; no code changes. Switch env and publish:

1. **Add mainnet env** (once):
   ```bash
   sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443
   ```

2. **Switch and publish**:
   ```bash
   sui client switch --env mainnet
   npm run publish
   ```
   Or in one go:
   ```bash
   npm run publish:mainnet
   ```
   Or with the script:
   ```bash
   SUI_NETWORK=mainnet ./scripts/deploy.sh
   ```

Ensure your wallet has mainnet SUI for gas. For production, consider a [dedicated RPC](https://docs.sui.io/references/cli/client) and set `SUI_RPC_URL` if you add a programmatic deploy script.

## Endpoints and config

- **RPC URLs**: See [docs/endpoints.md](docs/endpoints.md). Defaults:
  - Testnet: `https://fullnode.testnet.sui.io:443`
  - Mainnet: `https://fullnode.mainnet.sui.io:443`
  - Devnet: `https://fullnode.devnet.sui.io:443`
- **Config**: [config/networks.json](config/networks.json) is the source of truth. Optional [.env.example](.env.example) for `SUI_NETWORK` and `SUI_RPC_URL`.

## Scripts

| Command              | Description                          |
|----------------------|--------------------------------------|
| `npm run build`      | Build Move package (`move/vibex`)    |
| `npm run test`       | Run Move unit tests                  |
| `npm run publish`    | Publish (uses active env)            |
| `npm run publish:mainnet` | Publish to mainnet (--env mainnet) |
| `./scripts/deploy.sh`| Build + publish; uses `SUI_NETWORK` if set |
| `npm run deploy:ts` | Programmatic publish (env-based RPC and keypair). See [docs/deploy-ts.md](docs/deploy-ts.md). |

## Docs

- [docs/README.md](docs/README.md) – Links to official Sui docs (install, client, Move packages, publish).
- [docs/endpoints.md](docs/endpoints.md) – RPC endpoints and how this repo uses them.

## Layout

- `move/vibex/` – Move package (template for your contracts): `Move.toml`, `sources/`, `tests/`.
- `config/networks.json` – RPC URLs per network.
- `scripts/deploy.sh` – CLI-based deploy script.

Commit `Move.lock` and `Published.toml` (after first publish) to keep builds and deployments reproducible.
