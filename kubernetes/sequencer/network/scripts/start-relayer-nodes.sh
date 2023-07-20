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

export ASTRIA_SEQUENCER_RELAYER_celestia_bearer_token="$BEARER_TOKEN"

/usr/local/bin/astria-sequencer-relayer \
    --sequencer-endpoint=http://localhost:26657 \
    --celestia-endpoint=http://celestia-service:26658 \
    --validator-key-file=/cometbft/config/priv_validator_key.json \
    --bootnodes=/ip4/192.168.65.120/tcp/33900/p2p/12D3KooWJGy9JbZyi4JLF2PsBsuUm8Jn72qrHiQ5it5wygAAvHYb
