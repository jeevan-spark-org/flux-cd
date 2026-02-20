#!/usr/bin/env bash
set -euo pipefail

# Required env vars:
#   GITHUB_OWNER
#   GITHUB_REPOSITORY
# Optional env vars:
#   GITHUB_BRANCH (default: main)
#   AKS_RESOURCE_GROUP
#   AKS_CLUSTER_NAME

: "${GITHUB_OWNER:?GITHUB_OWNER is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

if [[ -n "${AKS_RESOURCE_GROUP:-}" && -n "${AKS_CLUSTER_NAME:-}" ]]; then
  az aks get-credentials -g "$AKS_RESOURCE_GROUP" -n "$AKS_CLUSTER_NAME" --overwrite-existing
fi

flux check --pre

flux bootstrap github \
  --owner="$GITHUB_OWNER" \
  --repository="$GITHUB_REPOSITORY" \
  --branch="$GITHUB_BRANCH" \
  --path="clusters/aks-prod" \
  --personal

echo "Flux bootstrap completed for clusters/aks-prod"
