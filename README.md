# Astria Dev Cluster

This repository contains configuration and related scripts for running Astria with [`kind` (Kubernetes and Docker)](https://kind.sigs.k8s.io/).

## Dependencies

Main dependencies

* docker - https://docs.docker.com/get-docker/
* kubectl - https://kubernetes.io/docs/tasks/tools/
* kind - https://kind.sigs.k8s.io/docs/user/quick-start/#installation

For contract deployment:

* Forge (part of Foundry) - https://book.getfoundry.sh/getting-started/installation

## Setup

In order to startup you will need to have docker running on your machine

```bash
# create control plane cluster
just create-control-plane

# ingress controller
just deploy-ingress-controller

# wait for ingress.
# NOTE: this may fail quickly with "error: no matching resources found".
#  please retry the command
just wait-for-ingress-controller

# Deploys Sequencer + local DA
just deploy-astria-local

# Deploys a geth rollup chain + faucet + blockscout + ingress
just deploy-rollup
```

### Configuring Funding of Geth

By default, running this local node will fund a wallet address `0xaC21B97d35Bf75A7dAb16f35b111a50e78A72F30`, which you can add to your preferred wallet using the private key in `kubernetes/geth/key/private_key.txt`. This account should never be used for anything but test transactions.

To change the wallet account which receives funds, alter the `alloc` section of `kubernetes/geth/genesis/geth-genesis.json`

### Faucet

The faucet is reachable at http://faucet.astria.localdev.me.

By default, the faucet is funded by the account that is funded during geth genesis. This is configured by using the private key of the funded account in `start-faucet.sh`. This key is defined in `kubernetes/faucet/config-maps.yml` and is identical to the key in `kubernetes/geth/key/private_key.txt`.

### Connecting Metamask

* add custom network
    * network name: `astria-local`
    * rpc url: `http://executor.astria.localdev.me`
    * chain id: `912559`
    * currency symbol: `ETH`

## Deployments and Containers

| Deployment       | Containers                    |
|------------------|-------------------------------|
| `celestia-local` | celestia-app, celestia-bridge |
| `sequencer`      | metro, sequencer-relayer      |
| `geth`           | geth, conductor               |
| `faucet`         | faucet                        |
| `blockscout`     | blockscout + more             |

### Restarting Deployments

It is possible to restart running pods without restarting the entire cluster. This is useful for debugging and development.

NOTE: when restarting `celestia-local`, you will also need to restart `sequencer` and `geth`.

```bash
kubectl rollout restart deployment -n astria-dev-cluster [deployment-name]
```

### Helpful commands

The following commands are helpful for interacting with the cluster and its resources. These may be useful for debugging and development, but are not necessary for running the cluster.

```bash
# list all containers within a deployment
kubectl get -n astria-dev-cluster deployment DEPLOYMENT_NAME -o jsonpath='{.spec.template.spec.containers[*].name}'

# log the entire astria cluster
kubectl logs -n astria-dev-cluster -l app=astria-dev-cluster -f

# log nginx controller
kubectl logs -n ingress-nginx -f deployment/ingress-nginx-controller

# list nodes
kubectl get -n astria-dev-cluster nodes

# list pods
kubectl get --all-namespaces pods
kubectl get -n astria-dev-cluster pods

# to log a container you need to first grab the pod name from above
kubectl logs -n astria-dev-cluster -c CONTAINER_NAME POD_NAME

# delete cluster and resources
just clean

# example of deploying contract w/ forge (https://github.com/foundry-rs/foundry)
RUST_LOG=debug forge create --private-key $PRIV_KEY --rpc-url "http://executor.astria.localdev.me" src/Storage.sol:Storage
```

### Helpful links

* https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
* https://kubernetes.io/docs/concepts/configuration/configmap/
* https://kubernetes.io/docs/reference/kubectl/cheatsheet/
* https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_logs/
