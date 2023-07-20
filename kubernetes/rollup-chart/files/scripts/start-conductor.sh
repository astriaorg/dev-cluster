#!/bin/bash

set -o errexit -o nounset -o pipefail

# request token from http://celestia-token.astria.localdev.me/ and save to SequencerRelayerConfig.toml

# FIXME - how to use `token-svc` port here instead of hardcoding?
BEARER_TOKEN=$(wget -qO- http://celestia-service:5353)

if [ -z "$BEARER_TOKEN" ]; then
    echo "Failed to fetch the Celestia bearer token."
    exit 1
fi

echo "Celestia Bearer token fetched successfully."

echo "celestia_bearer_token = \"$BEARER_TOKEN\"" > "$home_dir"/SequencerRelayerConfig.toml

export ASTRIA_celestia_bearer_token="$BEARER_TOKEN"

# TODO - use $gossipnet_port instead of hardcoded 33900
/usr/local/bin/astria-conductor \
  --tendermint-url=$cometbft_rpc_endpoint \
  --celestia-node-url=$celestia_node_url \
  --chain-id=$evm_chain_id \
  --execution-rpc-url=http://localhost:$executor_host_grpc_port \
  --bootnodes=/ip4/192.168.65.120/tcp/33900/p2p/12D3KooWJGy9JbZyi4JLF2PsBsuUm8Jn72qrHiQ5it5wygAAvHYb
