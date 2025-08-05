#!/bin/bash

NAMESPACE="test-ns"
export USER=admin
export PASSWORD=admin
export KEYCLOAK_REALM=master
export KEYCLOAK_CLIENT_ID=dummy-client-id
export KEYCLOAK_CLIENT_SECRET="dummy-client-secret"
export KEYCLOAK_URL="keycloak.default.svc.cluster.local"
export MODEL_URL="vllm-llama-8b-service.default.svc.cluster.local"

test_keycloak_endpoint()
{
    for i in $(seq 1 5); do
        RESPONSE=$(kubectl exec -n $NAMESPACE curl-pod -- curl -s -o /dev/null -w "%{http_code}" $KEYCLOAK_URL/realms/master/protocol/openid-connect/token -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=password&client_id=${KEYCLOAK_CLIENT_ID}&client_secret=${KEYCLOAK_CLIENT_SECRET}&username=${USER}&password=${PASSWORD}" -H 'Content-Type: application/json')
        if [ "$RESPONSE" -ne 200 ]; then
            echo "ISTIO Mode DISABLED in $NAMESPACE namespace. mTLS PeerAuthentication applied."
            echo "Received HTTP status code $RESPONSE"
        else
            echo "ISTIO Mode Enabled in $NAMESPACE namespace."
            echo "Received HTTP status code $RESPONSE"
        fi

        sleep 1
    done
}

test_model_endpoint()
{
    for i in $(seq 1 100); do
        RESPONSE=$(kubectl exec -n $NAMESPACE curl-pod -- curl -s -o /dev/null -w "%{http_code}" $MODEL_URL/v1/models)
        #RESPONSE=$(kubectl exec -n $NAMESPACE curl-pod -- curl -s -o /dev/null -w "%{http_code}" $MODEL_URL/v1/chat/completions -X POST -d '{"messages": [{"role": "system","content": "You are helpful assistant"},{"role": "user","content": "what is API"}],"model": "deepseek-ai/DeepSeek-R1-Distill-Llama-70B","max_tokens": 100,"temperature": 0.4}' -H 'Content-Type: application/json')

        if [ "$RESPONSE" -ne 200 ]; then
            echo "ISTIO Mode DISABLED in $NAMESPACE namespace. mTLS PeerAuthentication applied."
            echo "Received HTTP status code $RESPONSE"
        else
            echo "ISTIO Mode Enabled in $NAMESPACE namespace."
            echo "Received HTTP status code $RESPONSE"
        fi

        sleep 1
    done
}


echo "### ISTIO mTLS feature test ###"
test_keycloak_endpoint
test_model_endpoint
echo "### End of script ###"