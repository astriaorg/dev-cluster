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

By default, running this local rollup will fund a wallet address `0xaC21B97d35Bf75A7dAb16f35b111a50e78A72F30`, which you can add to your preferred wallet using the private key in `helm/rollup/files/keys/private_key.txt`. This account should never be used for anything but test transactions.

To change the wallet account which receives funds, use the `deploy-rollup` command with the optional arguments `evm_funding_address` and `evm_funding_private_key`.

```bash
# create control plane cluster
just create-cluster

# ingress controller
just deploy-ingress-controller

# wait for ingress.
just wait-for-ingress-controller

# Deploy ingress
just deploy-astria-ingress

# Deploys ingress + Sequencer + local DA
just deploy-astria-local

# To deploy the whole stack (rollup included) locally with one command
just deploy-all-local

# Deploys a geth rollup chain + faucet + blockscout + ingress
# w/ defaults
# NOTE - default values can be found in `helm/rollup/values.yaml`
just deploy-rollup
# w/ custom name and id
just deploy-rollup <rollup_name> <network_id>
# w/ custom name, id, and funding address
just deploy-rollup <rollup_name> <network_id> <evm_funding_address> <evm_funding_private_key>

# Delete default rollup
just delete-rollup
# Delete custom rollup
just delete-rollup <rollup_name>

# Delete local persisted data
just clean-persisted-data
```

### Faucet

The default faucet is available at http://faucet.astria.localdev.me. 

If you deploy a custom faucet, it will be reachable at http://faucet.<rollup_name>.localdev.me.

By default, the faucet is funded by the account that is funded during geth genesis. This is configured by using the private key of the funded account in `start-faucet.sh`. This key is defined in `helm/rollup/values.yaml` and is identical to the key in `helm/rollup/files/keys/private_key.txt`.

### Blockscout

The default Blockscout app is available at http://blockscout.astria.localdev.me.

If you deploy a custom Blockscout app, it will be available at http://blockscout.<rollup_name>.localdev.me.

### Connecting Metamask

* adding the default network
  * network name: `astria`
  * rpc url: `http://executor.astria.localdev.me`
  * chain id: `912559`
  * currency symbol: `RIA`

* adding a custom network
    * network name: `<rollup_name>`
    * rpc url: `http://executor.<rollup_name>.localdev.me`
    * chain id: `<network_id>`
    * currency symbol: `RIA`

## Deployments and Containers

| Deployment       | Containers                             |
|------------------|----------------------------------------|
| `celestia-local` | celestia-app, celestia-bridge          |
| `sequencer`      | cometbft, sequencer, sequencer-relayer |
| `geth`           | geth, conductor                        |
| `faucet`         | faucet                                 |
| `blockscout`     | blockscout + more                      |

### Restarting Deployments

It is possible to restart a deployment without restarting the entire cluster. This is useful for debugging and development.

NOTE: when restarting `celestia-local`, you will also need to restart `sequencer` and `geth`.

```bash
# get deployments
kubectl get deployments --all-namespaces
# restart deployment
just restart <DEPLOYMENT_NAME>
```

### Using a local image

Deployment files can be updated to use a locally built docker image, for testing of local changes. In order to build an image from the monorepo see docs in the monorepo [here](https://github.com/astriaorg/astria/#docker-build).

Once you have a locally built image, update the image in the relevant deployment to point to your local image. In order to run, you will need to load the locally built image into the cluster. If you don't already have a cluster running, first run:

```bash
# create control plane cluster
just create-cluster
```

Then you can run the load-image command with your image name. For instance, if we have created a local image `astria-sequencer:local`

```bash
# load image into cluster
just load-image astria-sequencer:local
```

Now you can run the rest of the full cluster.

If you already had a running cluster, you only need to redeploy the component with the custom image [(see below)](#redeploying-deployments). If the image is a part of a rollup delete it and redeploy:

```
just delete-rollup <ROLLUP_NAME>
just deploy-rollup <ROLLUP_NAME> <NETWORK_ID>
```

### Redeploying Deployments

If you want to restart deployments which participate in p2p (`sequencer`, `geth`) you must completely redeploy.

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
