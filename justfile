default:
  @just --list

create-cluster:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
  kubectl apply -f kubernetes/namespace.yml

deploy-secrets-store:
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
  helm install --debug {{chart}}-chart ./charts/{{chart}}

delete-chart chart:
  helm uninstall {{chart}}-chart

redeploy-chart chart:
  helm uninstall {{chart}}-chart
  helm install --debug {{chart}}-chart ./charts/{{chart}}

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
defaultSequencerStartBlock := ""
deploy-rollup rollupName=defaultRollupName networkId=defaultNetworkId genesisAllocAddress=defaultGenesisAllocAddress privateKey=defaultPrivateKey sequencerStartBlock=defaultSequencerStartBlock:
  helm install --debug \
    {{ if rollupName          != '' { replace('--set config.rollup.name=# --set config.rollup.chainId=#chain', '#', rollupName) } else { '' } }} \
    {{ if networkId           != '' { replace('--set config.rollup.networkId=#', '#', networkId) } else { '' } }} \
    {{ if genesisAllocAddress != '' { replace('--set config.rollup.genesisAccounts[0].address=#', '#', genesisAllocAddress) } else { '' } }} \
    {{ if privateKey          != '' { replace('--set config.faucet.privateKey=#', '#', privateKey) } else { '' } }} \
    {{ if sequencerStartBlock != '' { replace('--set config.sequencer.initialBlockHeight=#', '#', sequencerStartBlock) } else { '' } }} \
    {{rollupName}}chain-chart-deploy ./charts/rollup

wait-for-rollup rollupName=defaultRollupName:
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-geth --for=condition=Available=True --timeout=600s
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-blockscout --for=condition=Available=True --timeout=600s

defaultRollupNameForDelete := "astria"
delete-rollup rollupName=defaultRollupNameForDelete:
  helm uninstall {{rollupName}}chain-chart-deploy

deploy-all-local: create-cluster deploy-ingress-controller wait-for-ingress-controller deploy-astria-local wait-for-sequencer (deploy-chart "sequencer-faucet") deploy-rollup wait-for-rollup

clean:
  kind delete cluster --name astria-dev-cluster

clean-persisted-data:
  rm -r /tmp/astria
