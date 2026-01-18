#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export KUBECONFIG="${SCRIPT_DIR}/kubeconfig"

echo "Installing ArgoCD..."

kubectl apply -f "${SCRIPT_DIR}/argocd-ns.yaml"
kubectl apply -f "${SCRIPT_DIR}/argocd-install.yaml"

echo "Waiting for ArgoCD to be ready..."
kubectl wait --namespace argocd \
  --for=condition=available \
  --selector=app.kubernetes.io/part-of=argocd \
  deployment \
  --timeout=600s

echo "ArgoCD installed successfully!"

echo "Getting admin password..."
kubectl get secret argocd-initial-admin-secret \
  --namespace argocd \
  --output jsonpath='{.data.password}' | base64 -d

echo ""
echo "To access ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Username: admin"
echo "  Password: <output from above>"
