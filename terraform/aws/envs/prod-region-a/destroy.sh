#!/bin/bash

set -e

ROOT_DIR=$(pwd)
ONPREM_CONTEXT="kubernetes-admin@kubernetes"


destroy_layer () {

  LAYER=$1

  echo ""
  echo "Destroy ${LAYER}"

  cd "${ROOT_DIR}/${LAYER}"

  terraform destroy -auto-approve
}

destroy_layer "04-eks-workloads"

destroy_layer "03-platform"

destroy_layer "02-eks"

destroy_layer "01-network"

# =========================================================
# 로컬 kubeconfig 컨텍스트 정리 및 온프레미스 복귀
# =========================================================
echo ""
echo "================================="
echo " Cleaning up local kubeconfig contexts"
echo "================================="

# 활성 컨텍스트를 온프레미스로 강제 복귀
kubectl config use-context "${ONPREM_CONTEXT}"

# 이미 물리적으로 삭제된 EKS 관련 로컬 컨텍스트 찌꺼기 삭제 (eks-a 별칭 삭제)
kubectl config delete-context eks-a || true

# 'cluster/hello-eks'가 포함된 모든 컨텍스트 동적 감지하여 삭제 
for ctx in $(kubectl config get-contexts -o name | grep "cluster/hello-eks"); do
  kubectl config delete-context "$ctx" || true
done