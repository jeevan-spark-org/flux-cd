# flux-cd (AKS GitOps)

GitOps repository for deploying `todo-api` to Azure Kubernetes Service (AKS) with Flux v2.

This repo follows a production-oriented layout:

- `clusters/` -> cluster entrypoints and Flux bootstrap state
- `infrastructure/` -> shared/platform sources and controllers
- `apps/` -> workload definitions (HelmRelease/Kustomize)
- `scripts/` -> bootstrap and validation helpers

## Prerequisites

- Azure CLI (`az`) authenticated to your tenant/subscription
- `kubectl`
- `flux` CLI v2
- Access to the AKS cluster
- A Git hosting repo for this directory

## Repository structure

- `clusters/aks-prod` is the reconciliation root for the production AKS cluster.
- `infrastructure/aks-prod/sources` defines the `GitRepository` source for `todo-api`.
- `apps/aks-prod/todo-api` defines namespace + `HelmRelease`.

## 1) Bootstrap Flux to AKS

1. Create this repo in GitHub (or your Git provider) and push this content.
2. Set context to AKS:
   - `az aks get-credentials -g <RESOURCE_GROUP> -n <AKS_CLUSTER_NAME> --overwrite-existing`
3. Run bootstrap script:
   - `./scripts/bootstrap-github.sh`

This bootstraps Flux and configures it to reconcile from `clusters/aks-prod`.

## 2) Configure app source and image settings

Update placeholders before first deploy:

- `infrastructure/aks-prod/sources/todo-api-gitrepository.yaml`
  - Replace `https://github.com/<org>/todo-api.git`
- `apps/aks-prod/todo-api/helmrelease.yaml`
  - Replace image repository `myacr.azurecr.io/todo-api`
  - Replace image tag with your tested release version

## 3) Runtime secret values

`todo-api` needs runtime DB values. Do **not** commit real secrets.

- Use the template at `apps/aks-prod/todo-api/todo-api-runtime-secret.example.yaml`
- Create the real secret in `flux-system` namespace through your secret manager flow
  (recommended: SOPS + Key Vault or External Secrets + Key Vault)

## 4) Reconcile and verify

- `flux get all -A`
- `flux reconcile source git flux-system`
- `flux reconcile kustomization flux-system -n flux-system`
- `kubectl get hr -n flux-system`
- `kubectl get pods -n todo-api`

## AKS/Flux best-practice notes used here

- Pull-based GitOps with Flux bootstrap
- Single reconciliation root per cluster (`clusters/aks-prod`)
- Declarative Helm release management via `HelmRelease`
- Drift detection enabled for the app release
- Retry/remediation policy for install/upgrade failures
- Namespace isolation for workload resources (`todo-api`)
- No plaintext secrets committed in Git

## Optional Azure extension path

If you prefer Azure-managed Flux extension (`microsoft.flux`) instead of `flux bootstrap`, you can install it via Azure CLI and still keep this same repository layout as source.
