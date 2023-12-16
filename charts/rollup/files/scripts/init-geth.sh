#!/bin/bash

set -o errexit -o nounset

exec geth --datadir $data_dir/ init /scripts/geth-genesis.json
