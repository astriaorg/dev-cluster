# Astria Dev Cluster

This repository contains configuration and related scripts for running Astria with [`kind`](https://kind.sigs.k8s.io/) (Kubernetes and Docker).

## Dependencies

Main dependencies

* kind - https://kind.sigs.k8s.io/docs/user/quick-start/#installation

For contract deployment:

* Forge (part of Foundry) - https://book.getfoundry.sh/getting-started/installation

## Setup

```bash
# create control cluster
just create-cluster

# ingress
just deploy-ingress-controller
# wait for ingress.
# NOTE: this may fail quickly with "error: no matching resources found".
#  please retry the command
just wait-for-ingress-controller

# deploy
just deploy-astria
```

### Helpful commands

```bash
# logs
just logs-nginx-controller
just logs-astria
just logs-container geth-executor

# list nodes
kubectl get -n astria-dev-cluster nodes

# list pods
kubectl get --all-namespaces pods
kubectl get -n astria-dev-cluster pods

# delete cluster and resources
just cleanup-astria
```

### Helpful links

* https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
* https://kubernetes.io/docs/concepts/configuration/configmap/
* https://kubernetes.io/docs/reference/kubectl/cheatsheet/
* https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_logs/
