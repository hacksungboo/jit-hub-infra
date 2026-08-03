# JIT-Hub Infra

> **JIT-Hub**: Just-In-Time Hybrid Cloud DR Platform
> 재해 상황에서만 클라우드 컴퓨팅 자원을 즉시 프로비저닝하는, 비용 효율적인 하이브리드 재해복구(DR) 플랫폼

이 저장소는 **JIT-Hub** 프로젝트의 인프라 코드와 GitOps 배포 설정을 관리합니다. Terraform, Ansible, Helm, ArgoCD, 모니터링/오토스케일링 스택을 기반으로 AWS와 온프레미스를 아우르는 3계층 하이브리드 DR 아키텍처를 코드로 정의하고 자동화합니다.

애플리케이션 코드는 별도 저장소([jit-hub-app](https://github.com/hacksungboo/jit-hub-app))에서 관리되며, 이 저장소는 그 애플리케이션을 실행/복구하기 위한 인프라 계층을 담당합니다.

---

## 프로젝트 배경 및 문제의식

전통적인 재해복구(DR) 전략은 크게 두 가지 축으로 나뉩니다.

- **Warm Standby / Pilot Light**: DR 리전에 최소한의 자원을 상시 대기시켜 빠르게 복구할 수 있지만, 평시에도 비용이 계속 발생합니다.
- **Cold Standby**: 평시 비용은 거의 없지만, 장애 발생 후 처음부터 인프라를 구축해야 해서 복구 시간이 길고, 그 사이 서비스가 완전히 중단됩니다.

JIT-Hub는 이 둘의 단점을 보완하기 위해 **온프레미스를 1차 방어선으로 세워 즉시 서비스 연속성을 확보하고, 진짜 필요한 순간(Just-In-Time)에만 클라우드 컴퓨팅 자원을 Terraform으로 프로비저닝**하는 구조를 제안합니다. 즉, 상시 대기 비용은 최소화하면서도 장애 발생 즉시 서비스가 끊기지 않도록 만드는 것이 이 프로젝트의 핵심 문제의식입니다.

## 프로젝트 목적

1. **멀티클라우드/하이브리드 DR 자동화** — 장애 감지부터 트래픽 전환, 인프라 프로비저닝, 애플리케이션 배포, 원상 복구까지 전 과정을 스크립트와 IaC로 자동화합니다.
2. **관측(Observability) 및 AI 기반 장애 분석의 생존성 확보** — 클라우드 장애와 무관하게 동작해야 하는 모니터링/로깅 스택을 온프레미스 중앙 허브에 두고, sLLM 기반 로그 분석으로 장애 유형을 자동 판별합니다.
3. **GreenOps/FinOps 관점의 비용 및 자원 최적화** — 평시 유휴 자원을 최소화하고, 오토스케일링과 이미지 경량화로 인프라 효율을 높입니다.

## 하이브리드 DR 아키텍처

JIT-Hub는 다음 3개 실행 영역(클러스터)을 기준으로 설계되었습니다.

| 영역 | 역할 | 평시 상태 |
| :--- | :--- | :--- |
| **`eks-a`** (AWS Region A) | 메인 서비스 클러스터 (Active) | 정상 트래픽 처리, 높은 replica로 운영 |
| **`onprem`** (온프레미스) | Standby 서비스 클러스터 + 메인 PostgreSQL DB + 중앙 관제(mgmt) | 최소 replica로 대기, 장애 시 즉시 승격 |
| **`eks-b`** (AWS Region B) | JIT 프로비저닝으로 활성화되는 DR 클러스터 (Cold Standby) | 네트워크 등 기반 인프라만 유지, 컴퓨팅은 평시 미기동 |

### 장애 대응 흐름 (Make-Before-Break)

1. **1차 방어 — 온프레미스로 즉시 전환**: `eks-a` 장애 감지 시 Cloudflare Tunnel(cloudflared)의 replica 수를 조정(eks-a: 1→0, onprem: 0→1)해 온프레미스 standby로 트래픽을 우회시켜 서비스 중단을 최소화합니다.
2. **2차 복구 — Region B JIT 프로비저닝**: 장애가 장기화되면 Terraform으로 `eks-b`(02-eks → 03-platform → 04-eks-workloads → 05-eks-autoscaling)를 순차 프로비저닝하고, ArgoCD ApplicationSet을 재적용해 GitOps 동기화를 수행합니다. 배포 완료 후 Cold Standby 상태(replica 0)였던 애플리케이션을 1개씩 활성화하고, 헬스체크 통과 후 온프레미스에서 `eks-b`로 최종 트래픽을 전환합니다.
3. **원상 복구 — Primary 복귀**: `eks-a`가 복구되면 다시 정상 상태로 트래픽을 되돌립니다.

이 흐름은 `failover-scripts/` 아래 4개 스크립트(00-failover-common, 01-switch-to-onprem, 02-provision-dr, 03-restore-primary)와 이를 총괄하는 `approve-dr.sh`로 자동화되어 있으며, 각 단계마다 헬스체크와 실패 시 replica 롤백 로직을 포함합니다.

### 핵심 설계 요소

- **Terraform 모듈화**: EKS 네트워크/보안 분리, VPC, Karpenter, KEDA, ArgoCD 클러스터 자동 등록 모듈을 리전 A/B가 공유합니다.
- **Tailscale 하이브리드 연결**: AWS와 온프레미스 간 안전한 사설 네트워크 연결을 구성합니다.
- **GitOps (Hub & Spoke)**: 온프레미스 관리 클러스터(`mgmt`)에 설치된 ArgoCD가 Hub 역할을 하며, `eks-a`/`eks-b`/`onprem` 3개 Spoke 클러스터를 원격 제어합니다. ApplicationSet의 Matrix Generator로 여러 클러스터에 인프라/애플리케이션을 동시에 배포합니다.
- **중앙 관측 스택**: Prometheus, Grafana, Loki, Promtail을 온프레미스에 중앙 허브 형태로 구성해 클라우드 리전 장애와 분리된 관측 체계를 유지하고, Alertmanager → Loki 브릿지로 OOMKilled/DiskPressure 등 메트릭 기반 장애를 로그화합니다.
- **sLLM 기반 장애 로그 분석**: FastAPI + Ollama로 구현된 sLLM 서비스가 Loki 로그를 분석해 장애 유형(OOMKilled/DiskPressure/NetworkTimeout 등)을 판별하고, DR 전환 필요 여부를 자동 판단하며 Lambda를 통해 Slack으로 알립니다.
- **오토스케일링**: KEDA가 Prometheus 메트릭(요청량 등) 기반으로 Pod를 스케일링하고, Karpenter가 노드 프로비저닝과 컨솔리데이션(자원 회수)을 담당합니다.
- **GreenOps/FinOps**: Region B는 평시 컴퓨팅 자원을 아예 띄우지 않는 Cold Standby로 비용을 최소화하고, 온프레미스는 최소 리소스(requests/limits 이원화)로 운영하며, Karpenter consolidation으로 유휴 노드를 자동 회수합니다. 멀티스테이지 Docker 빌드로 이미지 용량도 경량화했습니다.

## CI/CD 파이프라인

- GitHub Actions가 커밋 변경분을 감지(path filter)해 **변경된 서비스만 선택적으로 빌드**합니다 (auth/gateway/weather/traffic/tourist/sllm 등 멀티서비스 matrix 빌드).
- 빌드된 이미지는 SHA 기반 태그로 **Harbor 레지스트리**에 푸시됩니다.
- 이후 별도 GitOps 저장소(이 저장소의 `gitops/`)의 Helm values 파일이 갱신되고, 이를 감지한 **ArgoCD가 온프레미스/EKS-A/EKS-B에 자동 배포**합니다.
- 애플리케이션 저장소와 인프라(GitOps) 저장소를 분리해, 애플리케이션 배포와 인프라 변경 이력을 독립적으로 관리합니다.

## 실제 구현 및 검증 결과

- VMware 기반 온프레미스 환경(mgmt/master/worker 노드)과 실제 AWS EKS 리전 A/B를 연동한 하이브리드 클러스터를 구성했습니다.
- `eks-a` 장애 상황을 가정한 DR 모의 훈련을 통해 온프레미스로의 즉시 전환과, Terraform 기반 `eks-b` 프로비저닝부터 GitOps 동기화, 애플리케이션 활성화, 최종 트래픽 전환까지 전 과정을 스크립트로 자동화하고 검증했습니다.
- Ansible로 온프레미스 관리 서버에 관측(Observability) 스택과 sLLM 기반 AI 장애 분석 스택을 배포해, 클라우드 리전과 독립적으로 동작하는 모니터링 체계를 구축했습니다.
- k6 기반 부하 테스트(`tests/load-test/`)로 각 서비스(tourist/traffic/weather)의 처리 용량과 KEDA 오토스케일링 동작을 검증했습니다.
- GitHub Actions 기반 선택적 빌드 및 Harbor → GitOps → ArgoCD로 이어지는 CI/CD 파이프라인을 실제 운영 환경에서 동작시켰습니다.

## 기술 스택

| 분류 | 기술 |
| :--- | :--- |
| IaC | Terraform, Ansible |
| 컨테이너 오케스트레이션 | Kubernetes (AWS EKS ×2 리전 + 온프레미스), Helm |
| GitOps / CD | ArgoCD (ApplicationSet, Hub & Spoke) |
| CI | GitHub Actions |
| 컨테이너 레지스트리 | Harbor |
| 네트워킹 | Cloudflare Tunnel(cloudflared), Route 53, Tailscale, Nginx Ingress |
| 오토스케일링 | KEDA, Karpenter |
| 모니터링/로깅 | Prometheus, Grafana, Loki, Promtail, Alertmanager |
| AI 기반 장애 분석 | FastAPI, Ollama (sLLM) |
| 부하 테스트 | k6 |
| 데이터베이스 | PostgreSQL (NFS 기반 영속성) |

## 저장소 구조

```text
terraform/
  aws/
    envs/
      prod-region-a/     # EKS-A (Active) 인프라: network → eks → platform → workloads → autoscaling
      dr-region-b/        # EKS-B (Cold Standby) 인프라, JIT 프로비저닝 대상
      personal-test/      # Lambda 기반 Slack 알림 등 부가 기능 테스트
    modules/               # EKS, VPC, Karpenter, KEDA, ArgoCD, Tailscale, Nginx 등 공용 모듈
  onprem/                  # 온프레미스 플랫폼 및 워크로드 (ArgoCD Hub, PostgreSQL 등)
  shared/                  # Cloudflare, Ingress 등 공용 모듈
  utils/                   # Harbor 터널, 로그 데몬셋 등 유틸리티
ansible/
  aws/                     # Tailscale 배포 플레이북 및 매니페스트
  onprem/                  # ArgoCD 설치/정리 플레이북
charts/                    # Helm 차트 (jit-hub-app, monitoring-stack, ops, cloudflared 등)
gitops/
  argocd/                  # ApplicationSet, 클러스터/프로젝트 등록 정보
  values/                  # eks-a / eks-b / onprem 환경별 Helm values
failover-scripts/          # DR 자동화 스크립트 (common, switch-to-onprem, provision-dr, restore-primary)
tests/load-test/           # k6 부하 테스트 스크립트
docs/                      # 작업 기록 및 연동 가이드
```

## 사용 방법 (개요)

1. **온프레미스 플랫폼 구성**: `terraform/onprem/01-onprem-platform`, `02-onprem-workloads`를 실행해 온프레미스 ArgoCD(Hub), PostgreSQL, Cloudflare Tunnel 등을 구성합니다.
2. **AWS 인프라 프로비저닝**: `terraform/aws/envs/prod-region-a`에서 `./deploy.sh`를 실행해 `01-network → 02-eks → 03-platform → 04-eks-workloads → 05-eks-autoscaling` 순서로 EKS-A를 구축합니다. (EKS-B는 평시 미기동 상태로, 장애 시 `failover-scripts/02-provision-dr.sh`가 동일한 방식으로 프로비저닝합니다.)
3. **GitOps 연동**: `gitops/argocd/`의 `jit-hub-project.yaml`, `onprem-cluster.yaml`을 적용하고, ApplicationSet을 통해 세 클러스터에 애플리케이션과 모니터링/운영 스택을 배포합니다.
4. **CI/CD**: 애플리케이션 코드를 수정해 푸시하면 GitHub Actions가 변경된 서비스만 빌드해 Harbor에 반영하고, GitOps 저장소의 values가 갱신되면 ArgoCD가 자동 동기화합니다.
5. **DR 훈련/실전 대응**: `failover-scripts/approve-dr.sh`를 실행해 장애 대응 전체 흐름(온프레미스 전환 → EKS-B 프로비저닝 → 트래픽 전환)을 자동으로 수행합니다.

각 디렉터리에는 더 상세한 가이드가 있는 하위 README가 포함되어 있습니다.

- [failover-scripts/README.md](./failover-scripts/README.md)
- [gitops/README.md](./gitops/README.md)
- [gitops/argocd/README.md](./gitops/argocd/README.md)
- [gitops/values/README.md](./gitops/values/README.md)
- [terraform/onprem/README.md](./terraform/onprem/README.md)

## 관련 저장소

- 애플리케이션 코드: [jit-hub-app](https://github.com/hacksungboo/jit-hub-app)
