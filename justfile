default:
  @just --list

create-cluster:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
  kubectl apply -f kubernetes/namespace.yml

deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  while ! kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s; do \
    sleep 1; \
  done

deploy pod:
  kubectl apply -k kubernetes/{{pod}}

delete pod:
  kubectl delete -n astria-dev-cluster deployment {{pod}}

restart pod:
  kubectl rollout restart -n astria-dev-cluster deployment {{pod}}

redeploy pod:
  kubectl delete -n astria-dev-cluster deployment {{pod}}
  kubectl apply -k kubernetes/{{pod}}

config-ingress-local:
  kubectl apply -f kubernetes/local-ingress.yml

deploy-astria-local: (deploy "celestia-local") (deploy "sequencer") config-ingress-local

defaultRollupName          := "astria"
defaultNetworkId           := ""
defaultGenesisAllocAddress := ""
defaultPrivateKey          := ""
deploy-rollup rollupName=defaultRollupName networkId=defaultNetworkId genesisAllocAddress=defaultGenesisAllocAddress privateKey=defaultPrivateKey:
  helm install --debug \
    {{ if rollupName          != '' { replace('--set rollupName=# --set evmChainId=#chain', '#', rollupName) } else { '' } }} \
    {{ if networkId           != '' { replace('--set evmNetworkId=#', '#', networkId) } else { '' } }} \
    {{ if genesisAllocAddress != '' { replace('--set genesisAllocAddress=#', '#', genesisAllocAddress) } else { '' } }} \
    {{ if privateKey          != '' { replace('--set privateKey=#', '#', privateKey) } else { '' } }} \
    {{rollupName}}chain-chart-deploy ./kubernetes/rollup

defaultRollupNameForDelete := "astria"
delete-rollup rollupName=defaultRollupNameForDelete:
  helm uninstall {{rollupName}}chain-chart-deploy

clean:
  kind delete cluster --name astria-dev-cluster
