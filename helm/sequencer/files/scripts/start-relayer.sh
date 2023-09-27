#!/bin/bash

set -o errexit -o nounset -o pipefail

# FIXME - how to use `token-svc` port here instead of hardcoding?
BEARER_TOKEN=$(wget -qO- http://celestia-service:5353)

if [ -z "$BEARER_TOKEN" ]; then
    echo "Failed to fetch the Celestia bearer token."
    exit 1
fi

echo "Celestia Bearer token fetched successfully."

export ASTRIA_SEQUENCER_RELAYER_CELESTIA_BEARER_TOKEN="$BEARER_TOKEN"

/usr/local/bin/astria-sequencer-relayer

