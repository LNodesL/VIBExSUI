#!/usr/bin/env bash
# Deploy Move package using active sui client env.
# Optionally set SUI_NETWORK=testnet|mainnet|devnet to switch before publish (requires sui client envs configured).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PKG_DIR="$REPO_ROOT/move/vibex"

if [[ -n "${SUI_NETWORK:-}" ]]; then
  echo "Switching to env: $SUI_NETWORK"
  sui client switch --env "$SUI_NETWORK"
fi

echo "Building..."
(cd "$PKG_DIR" && sui move build)
echo "Publishing..."
(cd "$PKG_DIR" && sui client publish --gas-budget 100000000)
