#!/bin/bash

set -o errexit -o nounset -o pipefail

# Request Celestia token if connecting to celestia
BEARER_TOKEN=""
if [ "$ASTRIA_CONDUCTOR_DISABLE_FINALIZATION" = "false" ]; then
    BEARER_TOKEN=$(wget -qO- http://celestia-service:5353)

    if [ -z "$BEARER_TOKEN" ]; then
        echo "Failed to fetch the Celestia bearer token."
        exit 1
    fi

    echo "Celestia Bearer token fetched successfully."
fi

export ASTRIA_CONDUCTOR_CELESTIA_BEARER_TOKEN="$BEARER_TOKEN"

/usr/local/bin/astria-conductor
