default:
  @just --list

create-control-plane:
  kind create cluster --config ./kubernetes/kind-cluster-config.yml

deploy-ingress-controller:
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

wait-for-ingress-controller:
  kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=600s

deploy-astria:
  kubectl apply -k kubernetes/

wait-for-astria:
  kubectl wait -n astria-dev-cluster deployment astria-dev-cluster-deployment --for=condition=Available=True

clean:
  kind delete cluster --name astria-dev-cluster

logs-nginx-controller:
  kubectl logs --selector app=ingress-nginx --namespace ingress-nginx --container controller -f
  kubectl get -n ingress-nginx pods --no-headers=true | awk '/controller/{print $1}' | xargs kubectl logs -n ingress-nginx -f
