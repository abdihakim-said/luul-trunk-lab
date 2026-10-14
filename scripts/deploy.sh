#!/usr/bin/env bash
# Simulated deployment so the lab works without a real cluster.
# At a company this step would be: kubectl/helm upgrade, or (GitOps) updating the
# image tag in a config repo so Argo CD / Flux syncs it to Kubernetes.
set -euo pipefail
ENVIRONMENT="$1"
IMAGE="$2"

echo "==> Deploying $IMAGE to $ENVIRONMENT"
echo "    (real life: helm upgrade --install trunk-based-cicd-reference ./chart --set image=$IMAGE -n $ENVIRONMENT)"
echo "==> $ENVIRONMENT is now running $IMAGE"
