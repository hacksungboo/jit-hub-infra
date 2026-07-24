#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ARGOCD_CONTEXT="${ARGOCD_CONTEXT:-kubernetes-admin@kubernetes}"
CLEANUP_TIMEOUT="${ARGOCD_CLEANUP_TIMEOUT:-600}"

kc() { kubectl --context "${ARGOCD_CONTEXT}" --namespace argocd "$@"; }

destroy_layer() {
  echo -e "\n===== Destroying $1 ====="
  ( cd "${ROOT_DIR}/$1" && terraform init -input=false && terraform destroy -input=false -auto-approve )
}

cleanup_argocd() {
  echo -e "\n===== Cleaning up ArgoCD Applications ====="

  # 1. ApplicationSet 먼저 삭제 (Application 재생성 방지)
  kc delete applicationset --all --ignore-not-found --wait=true

  # 2. 모든 Application에 finalizer 부여 + auto-sync 중단
  for app in $(kc get applications.argoproj.io -o name); do
    kc patch "$app" --type merge \
      --patch '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]},"spec":{"syncPolicy":{"automated":null}}}' >/dev/null
  done

  # 3. 모든 Application 삭제 (백그라운드) 
  kc delete applications.argoproj.io --all --ignore-not-found --wait=false

  # 4. 실제로 다 사라질 때까지 대기 (finalizer가 관리 리소스 prune 완료해야 사라짐)
  local deadline=$((SECONDS + CLEANUP_TIMEOUT))
  while ((SECONDS < deadline)); do
    if [[ -z "$(kc get applications.argoproj.io -o name 2>/dev/null)" ]]; then
      echo "All ArgoCD Applications pruned."
      return 0
    fi
    echo "Waiting for Applications to be pruned... ($(kc get applications.argoproj.io -o name | wc -l) remaining)"
    sleep 5
  done

  echo "Timed out waiting for ArgoCD Applications." >&2
  return 1
}

echo "===== On-prem Terraform destroy start ====="
cleanup_argocd
destroy_layer "02-onprem-workloads"
destroy_layer "01-onprem-platform"
echo -e "\n===== On-prem Terraform destroy complete ====="