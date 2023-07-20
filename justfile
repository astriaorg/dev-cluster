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

deploy-astria-local: (deploy "celestia-local") (deploy "sequencer")

deploy-rollup: (deploy "geth") (deploy "faucet/local") (deploy "blockscout") config-ingress-local

wait-for-sequencer:
  kubectl wait -n astria-dev-cluster deployment sequencer --for=condition=Available=True --timeout=600s

wait-for-geth:
  kubectl wait -n astria-dev-cluster deployment geth --for=condition=Available=True --timeout=600s

clean:
  kind delete cluster --name astria-dev-cluster

# FIXME - i dont like having defaults here. is there a better way to have optional arguments here?
defaultGenesisAllocAddress := "0xb04f3ca3Ef3d2c7c0d1d6d165951caBb16B5B2fB"
defaultPrivateKey          := "8b3a7999072c9c9314c084044fe705db11714c6c4ed7cddb64da18ea270dd203"
deploy-rollup-chart rollupName networkId genesisAllocAddress=defaultGenesisAllocAddress privateKey=defaultPrivateKey:
  helm install --debug \
    --set rollupName={{rollupName}} \
    --set evmChainId={{rollupName}}chain \
    --set evmNetworkId={{networkId}} \
    --set genesisAllocAddress={{genesisAllocAddress}} \
    --set privateKey={{privateKey}} \
    {{rollupName}}chain-chart-deploy ./kubernetes/rollup-chart

delete-rollup-chart rollupName:
  helm uninstall {{rollupName}}chain-chart-deploy
