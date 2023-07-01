#!/bin/sh

set -o errexit -o nounset

./celestia bridge init \
  --node.store "$home_dir/bridge" \
  --core.ip 127.0.0.1 \
  --core.rpc.port $celestia_app_host_port \
  --gateway.port $bridge_host_port
cp -r "$home_dir/keyring-test" "$home_dir/bridge/keys/"
