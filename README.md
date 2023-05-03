# Astria Dev Cluster

This repository contains configuration and related scripts for running Astria with Podman.

## Dependencies
You must have Podman installed

https://podman.io/getting-started/installation

## Setup
```bash
# init and start podman machine
podman machine init
podman machine start

# create template yaml
# NOTE - replace the geth_local_account with your own account address
podman run --rm \
  -e pod_name=astria_stack \
  -e celestia_home_volume=celestia-home-vol \
  -e metro_home_volume=metro-home-vol \
  -e executor_home_volume=executor-home-vol \
  -e relayer_home_volume=relayer-home-vol \
  -e executor_local_account=0xb0E31D878F49Ec0403A25944d6B1aE1bf05D17E1 \
  -e celestia_app_host_port=26657 \
  -e bridge_host_port=26659 \
  -e sequencer_host_port=1318 \
  -e sequencer_host_grpc_port=9100 \
  -e executor_host_http_port=8545 \
  -e executor_host_grpc_port=50051 \
  -e scripts_host_volume="$PWD"/container-scripts \
  -v "$PWD"/templates:/data/templates \
  dcagatay/j2cli:latest \
  -o /data/templates/astria_stack.yaml \
  /data/templates/astria_stack.yaml.jinja2


# run pod
podman play kube --log-level=debug templates/astria_stack.yaml

# run cargo
# TODO - containerize and include in pod
cd your-repos/astria-conductor
git fetch --all
git checkout feature/podman
# get ConductorConfig.toml for conductor below
cargo run

# deploy test contract
git clone https://github.com/joroshiba/test-contracts
cd test-contracts
export PRIV_KEY=123...
RUST_LOG=debug forge create --private-key $PRIV_KEY src/Storage.sol:Storage
```

## ConductorConfig.toml
```toml
celestia_node_url = "http://localhost:26659"
tendermint_url = "http://localhost:1318"
chain_id = "ethereum"
execution_rpc_url = "http://localhost:50051"
```

### Helpful commands
```bash
# list running containers
podman ps

# stop running stack
podman pod stop astria_stack

# remove stack
podman pod rm astria_stack
```

### Helpful links
* https://podman.io/getting-started/
* https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
* https://kubernetes.io/docs/concepts/configuration/configmap/
* https://www.redhat.com/sysadmin/podman-play-kube-updates
* https://www.redhat.com/sysadmin/podman-mac-machine-architecture
