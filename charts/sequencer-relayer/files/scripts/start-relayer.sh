#!/bin/bash

set -o errexit -o nounset -o pipefail

if [ -z "$ASTRIA_SEQUENCER_RELAYER_CELESTIA_BEARER_TOKEN" ]; then
    # FIXME - how to use `token-svc` port here instead of hardcoding?
    BEARER_TOKEN=$(wget -qO- $TOKEN_SERVER)

    if [ -z "$BEARER_TOKEN" ]; then
        echo "Failed to fetch the Celestia bearer token."
        exit 1
    fi

    echo "Celestia Bearer token fetched successfully."
    export ASTRIA_SEQUENCER_RELAYER_CELESTIA_BEARER_TOKEN="$BEARER_TOKEN"
fi


/usr/local/bin/astria-sequencer-relayer

