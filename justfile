default:
  @just --list

create-control-plane:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml

deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  while ! kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s; do \
    sleep 1; \
  done

deploy-namespace:
  kubectl apply -f kubernetes/namespace.yml

deploy-celestia-local:
  kubectl apply -k kubernetes/celestia-local

deploy-sequencer:
  kubectl apply -k kubernetes/sequencer

deploy-geth:
  kubectl apply -k kubernetes/geth

faucet-default := 'local'

deploy-faucet type=faucet-default:
  kubectl apply -k kubernetes/faucet/{{type}}

deploy-blockscout:
  kubectl apply -k kubernetes/blockscout

deploy-ingress-local:
  kubectl apply -f kubernetes/local-ingress.yml

deploy-astria-local: deploy-namespace deploy-celestia-local deploy-sequencer

deploy-geth-local: deploy-geth deploy-faucet deploy-blockscout deploy-ingress-local

deploy-all-local: create-control-plane deploy-ingress-controller wait-for-ingress-controller deploy-astria-local deploy-geth-local

wait-for-astria:
  kubectl wait -n astria-dev-cluster deployment geth --for=condition=Available=True --timeout=600s

clean:
  kind delete cluster --name astria-dev-cluster
