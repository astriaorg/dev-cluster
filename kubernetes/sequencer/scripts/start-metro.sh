#!/bin/sh

set -o errexit -o nounset

sed -i'.bak' 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $home_dir/config/config.toml
sed -i'.bak' 's/timeout_propose = "10s"/timeout_propose = "1s"/g' $home_dir/config/config.toml

# Start the celestia-app
exec metro start --home "${home_dir}"
