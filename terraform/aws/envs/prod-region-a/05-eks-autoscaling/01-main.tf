# ── ECR Public 로그인 토큰 발급 ──
# Karpenter 차트가 public.ecr.aws에 있는데, 익명 pull도 토큰이 필요함.
# 이거 없으면 "403 Forbidden"으로 차트 다운로드 실패.
data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

# =========================================================
# 1) Karpenter 권한 세팅
# =========================================================
# KEDA는 클러스터 안에서 Pod 개수만 조절해서 AWS 권한이 필요 없었지만,
# Karpenter는 EC2를 직접 생성/삭제하므로 AWS 권한이 반드시 있어야 함.
# 이 모듈 하나가 아래 4개를 만들어 줌:
#   - Controller IAM Role : Karpenter Pod이 EC2를 만들 권한
#   - Node IAM Role       : 새로 만든 EC2가 클러스터에 조인할 권한
#   - EKS Access Entry    : EKS가 그 EC2를 정식 노드로 인정
#   - SQS 큐              : Spot 인스턴스 중단 알림 수신
module "karpenter_iam" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = "hello-eks"

  # IRSA = 쿠버네티스 ServiceAccount와 AWS IAM Role을 연결하는 방식
  # 02-eks에서 enable_irsa = true로 만들어둔 OIDC provider를 사용
  enable_irsa            = true
  irsa_oidc_provider_arn = data.terraform_remote_state.eks.outputs.oidc_provider_arn

  # karpenter 네임스페이스의 karpenter SA만 이 권한을 쓸 수 있음
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # Karpenter가 새로 만드는 EC2에 붙일 Role
  # ops-values.yaml의 karpenter.iamRole 값과 이름을 맞춤
  create_node_iam_role          = true
  node_iam_role_name            = "KarpenterNodeRole-eks-a"
  node_iam_role_use_name_prefix = false # 뒤에 랜덤 문자열 안 붙임

  # SSM: 노드에 문제 생겼을 때 세션 매니저로 접속하기 위함
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # aws-auth 대신 EKS access entry 방식으로 노드 등록
  create_access_entry = true
}

# =========================================================
# 2) Karpenter 설치 (Helm)
# =========================================================
# 위 1)에서 만든 Role ARN과 SQS 큐 이름을 넘겨받아 설치.
# 기존에는 values.yaml에 존재하지 않는 role 이름이 하드코딩돼 있어서
# Pod이 AccessDenied로 CrashLoopBackOff 났음.
module "karpenter" {
  source = "../../../modules/karpenter"

  release_name = "karpenter"
  namespace    = "karpenter"

  # 차트 다운로드용 인증 정보
  ecr_username = data.aws_ecrpublic_authorization_token.token.user_name
  ecr_password = data.aws_ecrpublic_authorization_token.token.password

  cluster_name     = "hello-eks"
  cluster_endpoint = data.aws_eks_cluster.cluster.endpoint

  # 1)에서 실제로 생성된 값들을 주입
  irsa_role_arn      = module.karpenter_iam.iam_role_arn
  interruption_queue = module.karpenter_iam.queue_name
}