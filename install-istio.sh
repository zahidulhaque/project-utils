#!/bin/bash

export TEST_NS="test-ns"
export DEFAULT_NS="default"
export INGRESS_NS="ingress-nginx"
export GENAI_GW_NS="genai-gateway"
export OBSERVABILITY_NS="observability"
export HABANA_NS="habana-ai-operator"

for np in $(kubectl get networkpolicies -n $GENAI_GW_NS -o jsonpath='{.items[*].metadata.name}'); do
  echo "patching networkpolicy -> $np"
  kubectl patch networkpolicy $np -n $GENAI_GW_NS -p '{"spec":{"ingress":[{"ports":[{"port":15008,"protocol":"TCP"},{"port":80,"protocol":"TCP"}]}]}}'
done

## INSTALL ISTIO in Ambient mode

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system --create-namespace --wait
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
helm install istiod istio/istiod --namespace istio-system --set profile=ambient --wait
helm install istio-cni istio/cni -n istio-system --set profile=ambient --wait
helm install ztunnel istio/ztunnel -n istio-system --wait
helm show values istio/istiod
helm ls -n istio-system
kubectl get pods -n istio-system

# kubectl delete networkpolicies. -n genai-gateway genai-gateway-postgresql genai-gateway-redis langfuse-clickhouse langfuse-minio langfuse-postgresql langfuse-valkey langfuse-zookeeper

kubectl label namespace $DEFAULT_NS istio.io/dataplane-mode=ambient
kubectl apply -f peer-authentication.yaml -n $DEFAULT_NS
kubectl label namespace $GENAI_GW_NS istio.io/dataplane-mode=ambient
kubectl apply -f peer-authentication.yaml -n $GENAI_GW_NS
kubectl label namespace $HABANA_NS istio.io/dataplane-mode=ambient
kubectl apply -f peer-authentication.yaml -n $HABANA_NS
kubectl label namespace $OBSERVABILITY_NS istio.io/dataplane-mode=ambient
kubectl apply -f peer-authentication.yaml -n $OBSERVABILITY_NS
kubectl label namespace $INGRESS_NS istio.io/dataplane-mode=ambient
kubectl apply -f peer-auth-ingress.yaml -n $INGRESS_NS


### Install Kiali

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/kiali.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/addons/grafana.yaml
kubectl patch svc kiali -n istio-system -p '{"spec": {"type": "NodePort"}}'

### Test mTLS

# kubectl apply -f pod-example.yaml
# kubectl label namespace $TEST_NS istio.io/dataplane-mode=ambient
# kubectl apply -f peer-authentication.yaml -n $TEST_NS
# kubectl label namespace $TEST_NS istio.io/dataplane-mode-
# kubectl delete -f peer-authentication.yaml -n $TEST_NS


# # ## Cleanup

# kubectl delete -f pod-example.yaml
# kubectl label namespace $DEFAULT_NS istio.io/dataplane-mode-
# kubectl label namespace $GENAI_GW_NS istio.io/dataplane-mode-
# kubectl label namespace $INGRESS_NS istio.io/dataplane-mode-
# kubectl delete -f peer-authentication.yaml -n $DEFAULT_NS
# kubectl delete -f peer-authentication.yaml -n $GENAI_GW_NS
# kubectl delete -f peer-auth-ingress.yaml -n $INGRESS_NS
# kubectl delete ns $TEST_NS
