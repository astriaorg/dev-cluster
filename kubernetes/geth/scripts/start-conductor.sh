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

/usr/local/bin/astria-conductor \
  --tendermint-url=http://sequencer-service:1318 \
  --celestia-node-url=http://celestia-service:26658 \
  --chain-id=ethereum \
  --execution-rpc-url=http://localhost:50051
