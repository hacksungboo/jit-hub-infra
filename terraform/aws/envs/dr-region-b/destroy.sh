#!/bin/bash

set -e

ROOT_DIR=$(pwd)
ONPREM_CONTEXT="kubernetes-admin@kubernetes"

echo "================================="
echo " Terraform Destroy Start"
echo "================================="

# Karpenter 노드와 ELB는 Terraform state에 없어 VPC 삭제를 막으므로 먼저 제거
# ScaledObject/NodePool은 KEDA/Karpenter보다 먼저 지워야 finalizer로 인한 timeout이 없음
cleanup_k8s () {
  echo ""
  echo "================================="
  echo " Cleaning up non-Terraform resources"
  echo "================================="

  if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "cluster not reachable, skip"
    return 0
  fi

  kubectl delete scaledobject --all -A --ignore-not-found --timeout=60s || true

  kubectl delete nodepool --all --ignore-not-found --timeout=120s || true
  kubectl delete ec2nodeclass --all --ignore-not-found --timeout=120s || true

  kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' \
    | while read ns name; do
        [ -z "$name" ] && continue
        kubectl delete svc "$name" -n "$ns" --ignore-not-found || true
      done

  sleep 120
}

destroy_layer () {
  LAYER=$1

  echo ""
  echo "================================="
  echo " Destroy ${LAYER}"
  echo "================================="

  cd "${ROOT_DIR}/${LAYER}"

  terraform init

  terraform destroy -auto-approve
}

cleanup_k8s

destroy_layer "05-eks-autoscaling"
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

