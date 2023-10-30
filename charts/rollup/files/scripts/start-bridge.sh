#!/bin/bash

set -o errexit -o nounset -o pipefail

function set_token() {
  # NOTE - this is a hack to get the token to the token-server directory.
  TOKEN=$(celestia bridge auth admin \
    --node.store "$home_dir/bridge" \
    --keyring.accname $validator_key_name)

  # Busybox's httpd doesn't support url rewriting, so it's not simple to server another file.
  # To support an ingress rule path of `/`, we write the token to index.html, which httpd serves by default.
  mkdir -p "$home_dir"/token-server
  echo "$TOKEN" >"$home_dir"/token-server/index.html
}

# only create token if it does not already exist
# FIXME - would it be bad to get a new token on every start?
if [ ! -f "$home_dir"/token-server/index.html ]; then
  set_token
fi

genesis_hash=$(curl -s -S -X GET "http://celestia-service:$celestia_app_host_port/block?height=1" | jq -r '.result.block_id.hash')
  if [ -z "$genesis_hash" ]; then
    echo "did not receive genesis hash from celestia; exiting"
    exit 1
  else
    echo "genesis hash received: $genesis_hash"
  fi

export CELESTIA_CUSTOM="test:$genesis_hash"
# --p2p.network "test:$celestia_custom"
export GOLOG_LOG_LEVEL="debug"

# fixes: keystore: permissions of key 'p2p-key' are too relaxed: required: 0600, got: 0660
# FIXME - how are the perms getting changed from the first start which works fine?
# NOTE - using `find` here to avoid chmod'ing the keyring-test directory
find "$home_dir/bridge/keys" -type f -exec chmod 0600 {} \;

echo "staring bridge!"
exec celestia bridge start \
  --node.store "$home_dir/bridge" \
  --core.ip "celestia-service" \
  --core.rpc.port "$celestia_app_host_port" \
  --gateway \
  --gateway.port "$bridge_host_port" \
  --gateway.deprecated-endpoints \
  --rpc.port "$bridge_rpc_port" \
  --keyring.accname "$validator_key_name"
