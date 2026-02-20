#!/usr/bin/env bash
set -euo pipefail

flux check
flux get sources all -A
flux get kustomizations -A
flux get helmreleases -A

kubectl get ns flux-system >/dev/null
kubectl get ns todo-api >/dev/null || true

echo "Validation checks completed"
