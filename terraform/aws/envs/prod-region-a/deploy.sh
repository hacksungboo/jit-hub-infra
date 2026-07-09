#!/bin/bash

set -e

ROOT_DIR=$(pwd)

echo "================================="
echo " Terraform Deployment Start"
echo "================================="

apply_layer () {
  LAYER=$1

  echo ""
  echo "================================="
  echo " Applying ${LAYER}"
  echo "================================="

  cd "${ROOT_DIR}/${LAYER}"

  terraform init

  terraform plan -out=tfplan

  terraform apply tfplan
}


apply_layer "01-network"

apply_layer "02-eks"

apply_layer "03-platform"

# =========================================================
# 4. Argo CD 클러스터 등록 및 GitOps YAML 적용
# =========================================================
echo ""
echo "================================="
echo " Registering EKS to On-Premise Argo CD"
echo "================================="

# ---------------------------------------------------------
# 환경 설정 변수 및 경로 지정
# ---------------------------------------------------------
# Argo CD가 가동 중인 온프레미스(VMware k8s)의 kubectl 컨텍스트 이름
ONPREM_CONTEXT="kubernetes-admin@kubernetes"

# Git 레포지토리의 루트 절대경로를 동적으로 찾음 (YAML 파일들 참조용)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || realpath "${ROOT_DIR}/../../../../")

# ---------------------------------------------------------
# 1. EKS 접속용 로컬 Kubeconfig 갱신
# ---------------------------------------------------------
# 생성된 AWS EKS 클러스터를 로컬 kubeconfig에 등록하고 별칭(Alias)을 'eks-a'로 지정
aws eks update-kubeconfig --name hello-eks --region ap-northeast-2 --alias eks-a

# ---------------------------------------------------------
# 2. 온프레미스 Argo CD 접속 정보 실시간 조회
# ---------------------------------------------------------
# 온프레미스 클러스터에서 Argo CD 서버의 LoadBalancer 서비스 IP 주소 추출
ARGOCD_SERVER_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --context "${ONPREM_CONTEXT}")

# 온프레미스 클러스터에서 초기 Admin 패스워드를 추출하고 Base64 디코딩
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" --context "${ONPREM_CONTEXT}" | base64 -d)

# ---------------------------------------------------------
# 3. Argo CD CLI 원격 로그인
# ---------------------------------------------------------
# 비-TLS 경고창을 자동 통과(echo "y")하여 온프레미스 Argo CD CLI 서버에 로그인 수행
echo "y" | argocd login "${ARGOCD_SERVER_IP}" --username admin --password "${ARGOCD_PASSWORD}" --insecure --grpc-web

# ---------------------------------------------------------
# 4. EKS-A 클러스터를 Argo CD에 연동 (Bearer Token 자동 생성)
# ---------------------------------------------------------
# EKS 클러스터에 Argo CD 관리용 SA(서비스 어카운트)를 생성하고 토큰 인증 정보로 연결
# --upsert 플래그를 사용하여 기존 설정이 있을 경우 덮어쓰도록 강제 설정
argocd cluster add eks-a --name eks-a --label environment=eks-a --upsert --yes

# ---------------------------------------------------------
# 5. GitOps 프로젝트 및 ApplicationSet 선언형 리소스 배포
# ---------------------------------------------------------
# 온프레미스 Argo CD에 멀티 클러스터 프로젝트(Project) 생성
kubectl apply -f "${REPO_ROOT}/gitops/argocd/projects/jit-hub-project.yaml" --context "${ONPREM_CONTEXT}"

# 온프레미스 Argo CD에 인프라(모니터링 등) 및 애플리케이션 자동 배포용 ApplicationSet 리소스 생성
kubectl apply -f "${REPO_ROOT}/gitops/argocd/applicationsets/infra-applicationset.yaml" --context "${ONPREM_CONTEXT}"
kubectl apply -f "${REPO_ROOT}/gitops/argocd/applicationsets/app-applicationset.yaml" --context "${ONPREM_CONTEXT}"

echo "================================="
echo " GitOps Configurations Applied!"
echo "================================="