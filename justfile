default:
  @just --list

create-cluster:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml
  helm repo add cilium https://helm.cilium.io/
  helm install cilium cilium/cilium --version 1.14.3 \
      -f ./values/cilium.yml \
      --namespace kube-system
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


defaultNamespace := "astria-dev-cluster"
deploy-chart chart namespace=defaultNamespace:
  helm install --debug {{chart}}-chart ./charts/{{chart}} --namespace namespace --create-namespace

delete-chart chart:
  helm uninstall {{chart}}-chart --namespace namespace

restart deployment:
  kubectl rollout restart -n astria-dev-cluster deployment {{deployment}}

deploy-astria-local: (deploy-chart "celestia-local") (deploy-sequencer-validator)
delete-astria-local: (delete-chart "celestia-local") (delete-sequencer-validator)

validatorName := "single"
deploy-sequencer-validator name=validatorName:
  helm install --debug \
    {{ replace('-f values/validators/#.yml' , '#', name) }} \
    -n astria-validator-{{name}} --create-namespace \
    {{name}}-sequencer-chart ./charts/sequencer
deploy-sequencer-validators: (deploy-sequencer-validator "node0") (deploy-sequencer-validator "node1") (deploy-sequencer-validator "node2")

delete-sequencer-validator name=validatorName:
  helm uninstall {{name}}-sequencer-chart -n astria-validator-{{name}}
delete-sequencer-validators: (delete-sequencer-validator "node0") (delete-sequencer-validator "node1") (delete-sequencer-validator "node2")

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
    {{ if rollupName          != '' { replace('--set config.rollup.name=# --set celestia-node.config.labelPrefix=#', '#', rollupName) } else { '' } }} \
    {{ if networkId           != '' { replace('--set config.rollup.networkId=#', '#', networkId) } else { '' } }} \
    {{ if genesisAllocAddress != '' { replace('--set config.rollup.genesisAccounts[0].address=#', '#', genesisAllocAddress) } else { '' } }} \
    {{ if privateKey          != '' { replace('--set config.faucet.privateKey=#', '#', privateKey) } else { '' } }} \
    {{ if sequencerStartBlock != '' { replace('--set config.sequencer.initialBlockHeight=#', '#', sequencerStartBlock) } else { '' } }} \
    {{rollupName}}chain-chart-deploy ./charts/rollup --namespace astria-dev-cluster

deploy-dev-rollup rollupName=defaultRollupName networkId=defaultNetworkId genesisAllocAddress=defaultGenesisAllocAddress privateKey=defaultPrivateKey sequencerStartBlock=defaultSequencerStartBlock:
  helm install --debug \
    {{ if rollupName          != '' { replace('--set config.rollup.name=# --set celestia-node.config.labelPrefix=#', '#', rollupName) } else { '' } }} \
    {{ if networkId           != '' { replace('--set config.rollup.networkId=#', '#', networkId) } else { '' } }} \
    {{ if genesisAllocAddress != '' { replace('--set config.rollup.genesisAccounts[0].address=#', '#', genesisAllocAddress) } else { '' } }} \
    {{ if privateKey          != '' { replace('--set config.faucet.privateKey=#', '#', privateKey) } else { '' } }} \
    {{ if sequencerStartBlock != '' { replace('--set config.sequencer.initialBlockHeight=#', '#', sequencerStartBlock) } else { '' } }} \
    -f values/rollup/dev.yaml \
    {{rollupName}}chain-chart-deploy ./charts/rollup --namespace astria-dev-cluster

wait-for-rollup rollupName=defaultRollupName:
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-geth --for=condition=Available=True --timeout=600s
  kubectl wait -n astria-dev-cluster deployment {{rollupName}}-blockscout --for=condition=Available=True --timeout=600s

defaultRollupNameForDelete := "astria"
delete-rollup rollupName=defaultRollupNameForDelete:
  helm uninstall {{rollupName}}chain-chart-deploy --namespace astria-dev-cluster

deploy-all-local: create-cluster deploy-ingress-controller wait-for-ingress-controller deploy-astria-local wait-for-sequencer (deploy-chart "sequencer-faucet") deploy-rollup wait-for-rollup

defaultHypAgentConfig         := ""
defaultHypRelayerPrivateKey   := ""
defaultHypValidatorPrivateKey := ""
deploy-hyperlane-agents rollupName=defaultRollupName agentConfig=defaultHypAgentConfig relayerPrivateKey=defaultHypRelayerPrivateKey validatorPrivateKey=defaultHypValidatorPrivateKey:
  helm install --debug \
    {{ if rollupName          != '' { replace('--set config.name=# --set global.namespace=#-dev-cluster', '#', rollupName) } else { '' } }} \
    {{ if agentConfig         != '' { replace('--set config.agentConfig=#', '#', agentConfig) } else { '' } }} \
    {{ if relayerPrivateKey   != '' { replace('--set config.relayer.privateKey=#', '#', relayerPrivateKey) } else { '' } }} \
    {{ if validatorPrivateKey != '' { replace('--set config.validator.privateKey=#', '#', validatorPrivateKey) } else { '' } }} \
    {{rollupName}}-hyperlane-agents-chart ./charts/hyperlane-agents --namespace astria-dev-cluster

delete-hyperlane-agents rollupName=defaultRollupNameForDelete:
  helm uninstall {{rollupName}}-hyperlane-agents-chart --namespace astria-dev-cluster

clean:
  kind delete cluster --name astria-dev-cluster

clean-persisted-data:
  rm -r /tmp/astria

deploy-local-metrics:
  kubectl apply -f kubernetes/metrics-server-local.yml
