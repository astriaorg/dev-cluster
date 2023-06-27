#!/bin/sh

set -o errexit -o nounset

/app/eth-faucet -httpport 8080 \
  -wallet.provider $rpc_url \
  -wallet.privkey $private_key
