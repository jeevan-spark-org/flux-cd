# flux-cd (AKS GitOps)

GitOps repository for deploying `todo-api` to Azure Kubernetes Service (AKS) with Flux v2.

This repo follows an environment-oriented layout:

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

- `clusters/aks-dev` and `clusters/aks-prod` are environment roots.
- `infrastructure/<env>/sources` defines the `OCIRepository` source for the `todo-api` Helm chart in ACR.
- `apps/<env>/todo-api` defines namespace + `HelmRelease`.

## Azure extension integration (default path)

This repository is intended to be consumed by the AKS Flux extension (`microsoft.flux`) from the infra Bicep deployment.

- Git source: `https://github.com/jeevan-spark-org/flux-cd`
- Branch: `main`
- Kustomizations:
  - `infra` -> `./infrastructure/aks-dev` or `./infrastructure/aks-prod`
  - `apps` -> `./apps/aks-dev` or `./apps/aks-prod` (depends on `infra`)

The AKS extension installs and manages Flux controllers in `flux-system`, while this repo hosts desired-state manifests and app definitions.

Artifact model used by this repo:

- Container image source: `<env-acr>.azurecr.io/todo-api:<tag>`
- Helm chart source: `oci://<env-acr>.azurecr.io/helm/todo-api:<chart-tag>`
- `HelmRelease` reads chart via Flux `OCIRepository` and deploys image tag from `values.image.tag`.

## Optional: Bootstrap Flux via CLI

1. Create this repo in GitHub (or your Git provider) and push this content.
2. Set context to AKS:
   - `az aks get-credentials -g <RESOURCE_GROUP> -n <AKS_CLUSTER_NAME> --overwrite-existing`
3. Run bootstrap script:
   - `./scripts/bootstrap-github.sh`

This bootstraps Flux and configures it to reconcile from a selected cluster path (for example, `clusters/aks-prod`).

## 2) Configure chart source and image settings

Update placeholders before first deploy:

- `infrastructure/<env>/sources/todo-api-chart-ocirepository.yaml`
  - Set the ACR hostname and chart `ref.tag`
- `apps/aks-prod/todo-api/helmrelease.yaml`
  - Set environment ACR image repository (`<env-acr>.azurecr.io/todo-api`)
  - Update image tag with your tested release version

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
