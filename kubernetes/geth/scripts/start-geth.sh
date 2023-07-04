#!/bin/bash

set -o errexit -o nounset

geth --datadir $home_dir/.astriageth/ --networkid=912559 \
  --http --http.addr "0.0.0.0" --http.port $executor_host_http_port --http.corsdomain='*' --http.vhosts "*" \
  --ws --ws.addr "0.0.0.0" --ws.port $executor_host_ws_port --ws.origins='*' \
  --grpc --grpc.addr "0.0.0.0" --grpc.port $executor_host_grpc_port \
  --metro.addr "sequencer-service" --metro.port $sequencer_host_grpc_port
