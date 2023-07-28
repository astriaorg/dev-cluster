#!/bin/bash

set -o errexit -o nounset

export CHAIN_ID=$evm_chain_id
export COMETBFT_RPC_ENDPOINT=$cometbft_rpc_endpoint

geth --datadir $data_dir/ --networkid=$evm_network_id \
  --http --http.addr "0.0.0.0" --http.port $executor_host_http_port --http.corsdomain='*' --http.vhosts "*" --http.api eth,net,web3,debug \
  --ws --ws.addr "0.0.0.0" --ws.port $executor_host_ws_port --ws.origins='*' \
  --grpc --grpc.addr "0.0.0.0" --grpc.port $executor_host_grpc_port
