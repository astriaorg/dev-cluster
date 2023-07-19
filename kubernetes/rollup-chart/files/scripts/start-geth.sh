#!/bin/bash

set -o errexit -o nounset

geth --datadir $data_dir/ --networkid=$evm_network_id \
  --http --http.addr "0.0.0.0" --http.port $executor_host_http_port --http.corsdomain='*' --http.vhosts "*" --http.api eth,net,web3,debug \
  --ws --ws.addr "0.0.0.0" --ws.port $executor_host_ws_port --ws.origins='*' \
  --grpc --grpc.addr "0.0.0.0" --grpc.port $executor_host_grpc_port \
  --metro.addr "sequencer-service" --metro.port $sequencer_host_grpc_port
