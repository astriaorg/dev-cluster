#!/bin/bash

set -o errexit -o nounset -o pipefail

genesis_hash=$(curl -s -S -X GET "http://127.0.0.1:$celestia_app_host_port/block?height=1" | jq -r '.result.block_id.hash')
if [ -z "$genesis_hash" ]
then
  echo "did not receive genesis hash from celestia; exiting"
  exit 1
else
  echo "genesis hash received: $genesis_hash"
fi

export CELESTIA_CUSTOM="test:$genesis_hash"
  # --p2p.network "test:$celestia_custom"
export GOLOG_LOG_LEVEL="debug"

# NOTE - this is a hack to get the token to the token-server.
# busybox's httpd doesn't support url rewriting, so to make
# the ingress rule path `/` we write the token to index.html
TOKEN=$(celestia bridge auth admin \
  --node.store "$home_dir/bridge" \
  --keyring.accname validator)
mkdir -p "$home_dir"/token-server
echo "$TOKEN" > "$home_dir"/token-server/index.html

exec celestia bridge start \
  --node.store "$home_dir/bridge" \
  --core.ip 127.0.0.1 \
  --core.rpc.port "$celestia_app_host_port" \
  --gateway \
  --gateway.port "$bridge_host_port" \
  --gateway.deprecated-endpoints \
  --keyring.accname "$validator_key_name"
