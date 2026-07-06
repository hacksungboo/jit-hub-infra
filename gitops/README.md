# GitOps 배포 설정 (`gitops/`)

하이브리드 DR 아키텍처를 기반으로 3개 대상 클러스터(`eks-a`, `eks-b`, `onprem`)에 애플리케이션 및 인프라를 배포하기 위한 ArgoCD 선언식 설정과 환경별 Values 저장소입니다.

## 🏗️ 배포 아키텍처 (Hub & Spoke)
*   **Hub**: 온프레미스 관리용 클러스터 (`mgmt`)에 ArgoCD가 설치되어 동작합니다.
*   **Spoke**: Hub ArgoCD가 아래의 3개 대상 클러스터를 원격 제어합니다.
    1.  `eks-a` (AWS 메인 Active 리전)
    2.  `eks-b` (AWS DR Cold Standby 리전 / Terraform JIT로 스케일업 제어)
    3.  `onprem` (온프레미스 Standby 클러스터 / 메인 DB 인접)

## 📁 하위 디렉터리 구성
1.  [argocd/](file:///home/user1/jit-hub-infra-test/gitops/argocd): 클러스터 등록 정보, 프로젝트 범위 설정, 멀티 클러스터 동적 배포 엔진인 `ApplicationSet` 매니페스트를 관리합니다.
2.  [values/](file:///home/user1/jit-hub-infra-test/gitops/values): 각 클러스터의 특성(Active, Standby, DR)에 대응하는 차트별 오버라이드 설정 값(Values)을 보관합니다.

---

## 🚀 로컬 개발/테스트 가이드 (Quick Start)
각 팀원이 본인의 VMware 환경에서 이 배포 매니페스트를 구동하고 자율 검증을 진행하는 절차입니다.

### 1. 로컬 K8s에 ArgoCD 설치
```bash
# 네임스페이스 생성 및 ArgoCD 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. 접속 및 로그인 (socat 설치 없이 NodePort 우회 방법)
K8s 워커 노드에 `socat`이 없어 `kubectl port-forward`가 정상적으로 동작하지 않거나 상시 접속을 원할 경우, `NodePort` 서비스로 신속하게 전환하여 외부 접근 경로를 확보합니다.
```bash
# NodePort 서비스로 전환
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# 노출된 NodePort 포트 번호 확인 (출력 결과의 443:xxxxx/TCP 포트 확인)
kubectl get svc argocd-server -n argocd
```
*   **브라우저 접속 주소**: `https://<K8s_Node_IP>:<확인한_NodePort_포트번호>`
*   **기본 로그인 ID**: `admin`
*   **초기 비밀번호 조회**:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

### 3. 개인 포크(Fork) 저장소 및 피처 브랜치에서 테스트하는 요령
본인의 작업 디렉터리에서 수정한 배포 설정이 ArgoCD에 반영되도록 엮는 흐름입니다.

1.  **ArgoCD UI에 본인의 포크 저장소 등록**: `Settings` ➡️ `Repositories` 에서 포크한 저장소(`...-test.git`) 주소를 연동합니다.
2.  **로컬에 Project 및 클러스터(`onprem`) 정보 적용**:
    ```bash
    kubectl apply -f gitops/argocd/projects/jit-hub-project.yaml
    kubectl apply -f gitops/argocd/clusters/onprem-cluster.yaml
    ```
3.  **테스트용 코드 임시 수정 (PR 전 원복 필수)**:
    *   `app-applicationset.yaml` 및 `infra-applicationset.yaml` 파일 내 `repoURL`을 **본인의 포크 깃허브 주소**로 임시 수정합니다.
    *   `targetRevision`을 `HEAD` 대신 **본인의 현재 작업 피처 브랜치명**(`feature/gitops-structure-init` 등)으로 임시 수정합니다.
    *   `jit-hub-project.yaml` 내 `sourceRepos` 목록에 **본인의 포크 깃허브 주소**를 임시 등록합니다.
    *   *수정 후*: Git에 커밋/푸시를 하고 `kubectl apply -f gitops/argocd/applicationsets/app-applicationset.yaml`을 적용하면 로컬 환경에서 정상 배포 작동 검증이 시작됩니다.
