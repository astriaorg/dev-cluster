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

```bash
# create control plane cluster
just create-control-plane

# ingress
just deploy-ingress-controller

# wait for ingress.
# NOTE: this may fail quickly with "error: no matching resources found".
#  please retry the command
just wait-for-ingress-controller

# deploy
just deploy-astria
```

### Connecting Metamask
* add custom network
  * network name: `astria-local`
  * rpc url: `http://executor.astria.localdev.me`
  * chain id: `1337`
  * currency symbol: `ETH`

### Helpful commands

The following commands are helpful for interacting with the cluster and its resources. These may be useful for debugging and development, but are not necessary for running the cluster.

```bash
# list all containers by name
kubectl get -n astria-dev-cluster deployments/astria-dev-cluster-deployment -o json | jq -r ".spec.template.spec.containers[] | .name"

# log the entire astria cluster
kubectl logs -n astria-dev-cluster -l app=astria-dev-cluster -f

# log a specific container
kubectl logs -n astria-dev-cluster -l app=astria-dev-cluster -f --container CONTAINER_NAME

# log nginx controller
kubectl logs -n ingress-nginx -f deployment/ingress-nginx-controller

# list nodes
kubectl get -n astria-dev-cluster nodes

# list pods
kubectl get --all-namespaces pods
kubectl get -n astria-dev-cluster pods

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
