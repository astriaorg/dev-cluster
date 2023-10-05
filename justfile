default:
  @just --list

create-cluster:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
  kubectl apply -f kubernetes/namespace.yml
  helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
  helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system


deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  while ! kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s; do \
    sleep 1; \
  done

load-image image:
  kind load docker-image {{image}} --name astria-dev-cluster

deploy-chart chart:
  helm install --debug {{chart}}-chart ./helm/{{chart}}

delete-chart chart:
  helm uninstall {{chart}}-chart

redeploy-chart chart:
  helm uninstall {{chart}}-chart
  helm install --debug {{chart}}-chart ./helm/{{chart}}

restart deployment:
  kubectl rollout restart -n astria-dev-cluster deployment {{deployment}}

deploy-astria-local: (deploy-chart "celestia-local") (deploy-chart "sequencer")

wait-for-sequencer:
  kubectl wait -n astria-dev-cluster deployment celestia-local --for=condition=Available=True --timeout=600s
  kubectl wait -n astria-dev-cluster deployment sequencer --for=condition=Available=True --timeout=600s

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
    {{rollupName}}chain-chart-deploy ./helm/rollup

wait-for-rollup rollupName=defaultRollupName:
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-geth --for=condition=Available=True --timeout=600s
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-blockscout --for=condition=Available=True --timeout=600s

defaultRollupNameForDelete := "astria"
delete-rollup rollupName=defaultRollupNameForDelete:
  helm uninstall {{rollupName}}chain-chart-deploy

deploy-all-local: create-cluster deploy-ingress-controller wait-for-ingress-controller deploy-astria-local wait-for-sequencer deploy-rollup wait-for-rollup

clean:
  kind delete cluster --name astria-dev-cluster

clean-persisted-data:
  rm -r /tmp/astria
