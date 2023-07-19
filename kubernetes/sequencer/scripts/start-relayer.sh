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

export ASTRIA_SEQUENCER_RELAYER_celestia_bearer_token="$BEARER_TOKEN"

/usr/local/bin/astria-sequencer-relayer \
  --sequencer-endpoint=http://localhost:26657 \
  --celestia-endpoint=http://celestia-service:26658 \
  --validator-key-file=/cometbft/config/priv_validator_key.json \
  --libp2p-private-key=/keys/libp2p.key \
    --bootnodes=/dns4/192.168.65.121/tcp/2451/p2p/12D3KooWGZ6aLzPyX1uSetAxLjYjas6Yf52bhpRmXMDnNusLV9ST

