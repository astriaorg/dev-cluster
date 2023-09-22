#!/bin/bash

set -o errexit -o nounset -o pipefail

# request token from http://celestia-token.astria.localdev.me/ and save to SequencerRelayerConfig.toml

# FIXME - how to use `token-svc` port here instead of hardcoding?
ASTRIA_CONDUCTOR_CELESTIA_BEARER_TOKEN=$(wget -qO- http://celestia-service:5353)

if [ -z "$ASTRIA_CONDUCTOR_CELESTIA_BEARER_TOKEN" ]; then
    echo "Failed to fetch the Celestia bearer token."
    exit 1
fi

echo "Celestia Bearer token fetched successfully."

/usr/local/bin/astria-conductor
