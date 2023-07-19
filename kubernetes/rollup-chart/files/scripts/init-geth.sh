#!/bin/bash

set -o errexit -o nounset

geth --datadir $data_dir/ init /scripts/geth-genesis.json
