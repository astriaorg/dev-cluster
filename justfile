default:
  @just --list

create-cluster:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml

deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s

deploy-astria:
  kubectl apply -k kubernetes/

cleanup-astria:
  kubectl delete all --all --namespace astria-dev-cluster

# logs
logs-nginx-controller:
  kubectl get -n ingress-nginx pods --no-headers=true | awk '/controller/{print $1}' | xargs kubectl logs -n ingress-nginx -f

logs-astria:
  kubectl get -n astria-dev-cluster pods --no-headers=true | awk '/deployment/{print $1}' | xargs kubectl logs -n astria-dev-cluster -f

logs-container container:
  kubectl get -n astria-dev-cluster pods --no-headers=true | awk '/deployment/{print $1}' | xargs kubectl logs -n astria-dev-cluster -f -c {{container}}
