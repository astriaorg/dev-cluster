#!/bin/sh

set -o errexit -o nounset

# FIXME - why is --overwrite needed now? did celestia-app change how it handles genesis.json creation?
echo "init"
celestia-appd init "$chainid" \
  --chain-id "$chainid" \
  --home "$home_dir" \
  --overwrite

echo "keys add"

celestia-appd keys --help

celestia-appd keys add \
  "$validator_key_name" \
  --keyring-backend="$keyring_backend" \
  --home "$home_dir" \
  --trace

echo "add-genesis-account"
validator_key=$(celestia-appd keys show "$validator_key_name" -a --keyring-backend="$keyring_backend" --home "$home_dir")
celestia-appd add-genesis-account \
  "$validator_key" \
  --home "$home_dir" \
  "$coins"

echo "gentx"
celestia-appd gentx \
  "$validator_key_name" \
  "$validator_stake" \
  --keyring-backend="$keyring_backend" \
  --chain-id "$chainid" \
  --home "$home_dir" \
  --orchestrator-address "$validator_key" \
  --evm-address "$evm_address"

echo "collect-gentxs"
celestia-appd collect-gentxs --home "$home_dir"
