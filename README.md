# JIT-Hub Infra

> Just-In-Time Hybrid DR Platform on Kubernetes

JIT-Hub Infra 저장소는 JIT-Hub 프로젝트의 인프라와 GitOps 구성을 관리합니다.  
Terraform, Ansible, Helm, ArgoCD, 모니터링 스택을 활용해 AWS와 온프레미스를 아우르는 하이브리드 DR 플랫폼을 코드로 정의합니다.

## 제공 내용

- Terraform 기반 AWS EKS A/B 리전 인프라
- Ansible 기반 온프레미스 PostgreSQL 및 standby Kubernetes 구성
- Helm 차트 및 GitHub Pages 기반 Helm Repository
- ArgoCD를 이용한 EKS-A / EKS-B / 온프레미스 멀티 클러스터 GitOps
- Cloudflare Tunnel 기반 트래픽 라우팅 및 Failover 구성
- KEDA 및 Karpenter 오토스케일링 설정
- Prometheus, Grafana, Loki, Promtail 모니터링 스택

## 하이브리드 DR 아키텍처

JIT-Hub는 다음 3개 실행 영역을 기준으로 설계되었습니다.

- `eks-a` : AWS 메인 서비스 클러스터
- `onprem` : 온프레미스 standby 서비스 클러스터 + 메인 PostgreSQL DB
- `eks-b` : JIT 프로비저닝으로 활성화되는 AWS DR 클러스터

A 리전 장애 시 Cloudflare Tunnel을 통해 먼저 온프레미스 standby 서비스로 우회하고,  
Terraform JIT 프로비저닝을 통해 B 리전을 활성화한 뒤 최종적으로 트래픽을 이관합니다.

## 저장소 구조 (예시)

```text
terraform/
  aws/
    modules/
    envs/
  onprem/
ansible/
  onprem/
charts/
  jit-hub-app/
  cloudflared/
  monitoring-stack/
  ops/
gitops/
  argocd/
  values/
docs/
  architecture/
  runbooks/
  finops-greenops/
```

## 사용 방법 (개요)

- Terraform으로 AWS 인프라(EKS A/B, VPC 등)를 프로비저닝합니다.
- Ansible로 온프레미스 DB, standby k8s, 관리 노드를 구성합니다.
- Helm 차트를 GitHub Pages를 통해 Helm Repository로 배포합니다.
- ArgoCD ApplicationSet으로 세 클러스터에 GitOps 배포를 수행합니다.

## 관련 저장소

- 애플리케이션 코드: `jit-hub-app`