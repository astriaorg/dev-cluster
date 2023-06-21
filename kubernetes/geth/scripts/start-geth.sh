#!/bin/bash

set -o errexit -o nounset

geth --datadir $home_dir/.astriageth/ --http --http.addr "0.0.0.0" --http.port=$executor_host_http_port \
  --ws --ws.addr "0.0.0.0" --ws.port=$executor_host_http_port --networkid=912559 --http.corsdomain='*' --ws.origins='*' \
  --grpc --grpc.addr "0.0.0.0" --grpc.port $executor_host_grpc_port \
  --http.vhosts "executor.astria.localdev.me" \
  --metro.addr "sequencer-service" --metro.port $sequencer_host_grpc_port