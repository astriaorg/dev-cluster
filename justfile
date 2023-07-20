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

# FIXME - i dont like having defaults here. is there a better way to have optional arguments here?
# TODO - sorta janky, but maybe parse from values.yml?
defaultRollupName          := "astria"
defaultNetworkId           := "912559"
defaultGenesisAllocAddress := "0xaC21B97d35Bf75A7dAb16f35b111a50e78A72F30"
defaultPrivateKey          := "8b3a7999072c9c9314c084044fe705db11714c6c4ed7cddb64da18ea270dd203"
deploy-rollup rollupName=defaultRollupName networkId=defaultNetworkId genesisAllocAddress=defaultGenesisAllocAddress privateKey=defaultPrivateKey:
  helm install --debug \
    --set rollupName={{rollupName}} \
    --set evmChainId={{rollupName}}chain \
    --set evmNetworkId={{networkId}} \
    --set genesisAllocAddress={{genesisAllocAddress}} \
    --set privateKey={{privateKey}} \
    {{rollupName}}chain-chart-deploy ./kubernetes/rollup

delete-rollup rollupName:
  helm uninstall {{rollupName}}chain-chart-deploy

clean:
  kind delete cluster --name astria-dev-cluster
