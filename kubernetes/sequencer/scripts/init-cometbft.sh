#!/bin/bash

set -o errexit -o nounset

cometbft init

sed -i'.bak' 's/timeout_commit = "1s"/timeout_commit = "15s"/g' /cometbft/config/config.toml
sed -i'.bak' 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/g' /cometbft/config/config.toml