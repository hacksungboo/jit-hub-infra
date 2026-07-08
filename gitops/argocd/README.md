# ArgoCD 엔진 설정 (`gitops/argocd/`)

ArgoCD Hub에서 관리하는 Spoke 클러스터 정보 및 동적 배포 오케스트레이션 설정을 정의하는 공간입니다.

## 📁 구성 요소

### 1. [projects/](file:///home/user1/jit-hub-infra-test/gitops/argocd/projects)
*   `jit-hub-project.yaml`
    *   보안 경계 및 배포 허용 범위(`AppProject`)를 정의합니다.
    *   허용된 Git 소스 레포지토리와 대상 클러스터(`eks-a`, `eks-b`, `onprem`)의 네임스페이스 매핑을 관리합니다.

### 2. [clusters/](file:///home/user1/jit-hub-infra-test/gitops/argocd/clusters)
*   ArgoCD가 Spoke 클러스터를 관리하게 하는 K8s Secret 정의 파일입니다.
*   **주의**: 각 클러스터의 레이블(`environment: eks-a` 등)은 `ApplicationSet`에서 각 클러스터의 `values.yaml` 경로를 완성하는 키로 작용합니다.
*   실제 환경에서는 API Endpoint 및 인증 정보(Token/roleARN)를 유효하게 기입하여 반영해야 합니다.

### 3. [applicationsets/](file:///home/user1/jit-hub-infra-test/gitops/argocd/applicationsets)
*   **`app-applicationset.yaml`**: `jit-hub-app`을 3개 클러스터에 배포하며 공통 values와 클러스터 전용 values를 조합시킵니다.
*   **`infra-applicationset.yaml`**: Matrix Generator를 통해 `monitoring-stack`, `ops` 차트를 클러스터에 한 번에 배포하도록 엮어줍니다.
