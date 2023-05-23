default:
  @just --list

kustomize:
  kubectl kustomize ./kubernetes -o ./kubernetes/astria-dev-cluster.yml

create-control-plane:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml

deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s

deploy-astria:
  kubectl apply -k kubernetes/
