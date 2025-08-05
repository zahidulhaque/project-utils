#!/bin/bash

export TEST_NS="test-ns"
export DEFAULT_NS="default"
export INGRESS_NS="ingress-nginx"
export GENAI_GW_NS="genai-gateway"
export OBSERVABILITY_NS="observability"
export HABANA_NS="habana-ai-operator"

export PATH=$PATH:/home/ubuntu/zahid-workspace/istio-patch/istio-1.26.1/bin

### Cleanup

kubectl label namespace $DEFAULT_NS istio.io/dataplane-mode-
kubectl label namespace $GENAI_GW_NS istio.io/dataplane-mode-
kubectl label namespace $OBSERVABILITY_NS istio.io/dataplane-mode-
kubectl label namespace $HABANA_NS istio.io/dataplane-mode-
kubectl label namespace $INGRESS_NS istio.io/dataplane-mode-


kubectl delete -f peer-authentication.yaml -n $DEFAULT_NS
kubectl delete -f peer-authentication.yaml -n $GENAI_GW_NS
kubectl delete -f peer-authentication.yaml -n $OBSERVABILITY_NS
kubectl delete -f peer-authentication.yaml -n $HABANA_NS
kubectl delete -f peer-auth-ingress.yaml -n $INGRESS_NS

kubectl delete -f pod-example.yaml
kubectl delete ns $TEST_NS


### DELETE ISTIO

kubectl label namespace default istio.io/use-waypoint-
istioctl waypoint delete --all
kubectl label namespace default istio.io/dataplane-mode-
istioctl uninstall -y --purge
kubectl delete namespace istio-system
helm delete istio-ingress -n istio-ingress
kubectl delete namespace istio-ingress
helm delete ztunnel -n istio-system
helm delete istio-cni -n istio-system
helm delete istiod -n istio-system
helm delete istio-base -n istio-system
kubectl get crd -oname | grep --color=never 'istio.io' | xargs kubectl delete
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml
kubectl delete namespace istio-system