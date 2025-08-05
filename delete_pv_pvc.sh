#!/bin/bash

export NAMESPACE=genai-gateway # observability # genai-gateway


echo "Listing all PVCs in namespace '$NAMESPACE':"
kubectl get pvc -n "$NAMESPACE"

echo "Removing finalizers from all PVCs in namespace '$NAMESPACE'..."
pvc_list=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
for pvc in $pvc_list; do
  echo "Patching PVC: $pvc to remove finalizers..."
  kubectl patch pvc "$pvc" -n "$NAMESPACE" --type='json' -p='[
    {
      "op": "remove",
      "path": "/metadata/finalizers"
    }
  ]' 2>/dev/null || echo "No finalizers to remove on PVC $pvc"
done

echo "Deleting all PVCs in namespace '$NAMESPACE'..."
kubectl delete pvc --all -n "$NAMESPACE"

echo "Waiting for PVCs to be deleted..."
while kubectl get pvc -n "$NAMESPACE" --no-headers | grep -q .; do
  echo "PVCs still exist, waiting 5 seconds..."
  sleep 5
done

echo "Listing all PVs:"
kubectl get pv -n $NAMESPACE

echo "Removing finalizers from PVs bound to PVCs in namespace '$NAMESPACE' or in Released/Available state..."

pv_to_patch=$(kubectl get pv -o json | jq -r --arg ns "$NAMESPACE" '
  .items[] | select(
    (.spec.claimRef.namespace == $ns) or
    (.status.phase == "Released") or
    (.status.phase == "Available")
  ) | .metadata.name
')

if [ -z "$pv_to_patch" ]; then
  echo "No PVs to patch."
else
  for pv in $pv_to_patch; do
    echo "Patching PV: $pv to remove finalizers..."
    kubectl patch pv "$pv" --type='json' -p='[
      {
        "op": "remove",
        "path": "/metadata/finalizers"
      }
    ]' 2>/dev/null || echo "No finalizers to remove on PV $pv"
  done
fi

echo "Deleting PVs bound to PVCs in namespace '$NAMESPACE' or in Released/Available state..."

if [ -z "$pv_to_patch" ]; then
  echo "No PVs to delete."
else
  for pv in $pv_to_patch; do
    echo "Deleting PV: $pv"
    kubectl delete pv "$pv" -n $NAMESPACE
  done
fi

# echo "*** Delete local-path-provisioner path ***"
sudo rm -rf /opt/local-path-provisioner/*
echo "Done."
