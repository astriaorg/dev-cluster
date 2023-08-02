# Astria Dev Cluster

This repository contains configuration and related scripts for running Astria with [`kind` (Kubernetes and Docker)](https://kind.sigs.k8s.io/).

## Dependencies

Main dependencies

* docker - https://docs.docker.com/get-docker/
* kubectl - https://kubernetes.io/docs/tasks/tools/
* helm - https://helm.sh/docs/intro/install/
* kind - https://kind.sigs.k8s.io/docs/user/quick-start/#installation
* just - https://just.systems/man/en/chapter_4.html

For contract deployment:

* Forge (part of Foundry) - https://book.getfoundry.sh/getting-started/installation

## Setup

In order to startup you will need to have docker running on your machine

### Configuring Funding of Geth

By default, running this local rollup will fund a wallet address `0xaC21B97d35Bf75A7dAb16f35b111a50e78A72F30`, which you can add to your preferred wallet using the private key in `kubernetes/rollup/files/keys/private_key.txt`. This account should never be used for anything but test transactions.

To change the wallet account which receives funds, use the `deploy-rollup` command with the optional arguments `evm_funding_address` and `evm_funding_private_key`.

```bash
# create control plane cluster
just create-cluster

# ingress controller
just deploy-ingress-controller

# wait for ingress.
just wait-for-ingress-controller

# Deploys Sequencer + local DA
just deploy-astria-local

# To deploy the whole stack locally with one command
just deploy-all-local

# Deploys a geth rollup chain + faucet + blockscout + ingress
# w/ defaults
# NOTE - default values can be found in `kubernetes/rollup/values.yaml`
just deploy-rollup
# w/ custom name and id
just deploy-rollup <rollup_name> <network_id>
# w/ custom name, id, and funding address
just deploy-rollup <rollup_name> <network_id> <evm_funding_address> <evm_funding_private_key>

# Delete rollup
just delete-rollup <rollup_name>
```

### Faucet

The faucet is reachable at http://faucet.<rollup_name>.localdev.me.

By default, the faucet is funded by the account that is funded during geth genesis. This is configured by using the private key of the funded account in `start-faucet.sh`. This key is defined in `kubernetes/faucet/config-maps.yml` and is identical to the key in `kubernetes/geth/key/private_key.txt`.

### Connecting Metamask

* add custom network
    * network name: `<rollup_name>`
    * rpc url: `http://executor.<rollup_name>.localdev.me`
    * chain id: `<network_id>`
    * currency symbol: `RIA`

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
just restart <DEPLOYMENT_NAME>
```

### Redeploying Deployments

When deploying pods which participate in p2p (`sequencer`, `geth`) you must completely redeployd

```bash
just redeploy <DEPLOYMENT_NAME>
```

### Helpful commands

The following commands are helpful for interacting with the cluster and its resources. These may be useful for debugging and development, but are not necessary for running the cluster.

```bash
# list all containers within a deployment
kubectl get -n astria-dev-cluster deployment <DEPLOYMENT_NAME> -o jsonpath='{.spec.template.spec.containers[*].name}'

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
kubectl logs -n astria-dev-cluster -c <CONTAINER_NAME> <POD_NAME>

# delete a single deployment
just delete -n astria-dev-cluster deployment <DEPLOYMENT_NAME>

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
