#!/bin/bash

set -e

ROOT_DIR=$(pwd)

# =========================================================
# 0. 온프레미스 Argo CD에서 EKS 클러스터 등록 해제
# =========================================================
echo "================================="
echo " Deregistering EKS from On-Premise Argo CD"
echo "================================="

ONPREM_CONTEXT="kubernetes-admin@kubernetes"

# 1. 온프레미스 Argo CD로부터 접속 정보 실시간 추출
ARGOCD_SERVER_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --context "${ONPREM_CONTEXT}")
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context "${ONPREM_CONTEXT}" | base64 -d)

# 2. Argo CD CLI 로그인 및 EKS-A 클러스터 제거 (Argo CD가 꺼져있거나 이미 지워진 경우에도 인프라 삭제는 계속되도록 || true 처리)
echo "Logging in to Argo CD..."
echo "y" | argocd login "${ARGOCD_SERVER_IP}" --username admin --password "${ARGOCD_PASSWORD}" --insecure --grpc-web || true

echo "Removing eks-a cluster..."
argocd cluster rm eks-a --yes || true


destroy_layer () {

  LAYER=$1

  echo ""
  echo "Destroy ${LAYER}"

  cd "${ROOT_DIR}/${LAYER}"

  terraform destroy -auto-approve
}


destroy_layer "03-platform"

destroy_layer "02-eks"

destroy_layer "01-network"

# =========================================================
# 5. 로컬 kubeconfig 컨텍스트 정리 및 온프레미스 복귀
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