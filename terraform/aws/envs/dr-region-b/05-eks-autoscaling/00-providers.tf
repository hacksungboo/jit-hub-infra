terraform {
  required_providers {
    # Karpenter는 IAM Role/SQS 등 AWS 리소스를 만들어야 해서 aws provider 필요
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

# ── DR 리전 도쿄 ──
provider "aws" {
  region = "ap-northeast-1"
}

# ── ECR Public 전용 (버지니아) ──
# public.ecr.aws의 인증 토큰은 us-east-1에서만 발급됨.
# Karpenter 차트를 여기서 받기 때문에 별도 alias provider가 필요.
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

# ── EKS 클러스터 접속 정보 ──
data "aws_eks_cluster" "cluster" {
  name = "hello-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "hello-eks"
}

# ── 02-eks의 출력값 읽기 (OIDC provider ARN 용) ──
# 03-platform/00-providers.tf와 동일한 방식
data "terraform_remote_state" "eks" {

  backend = "local"

  config = {
    path = "../02-eks/terraform.tfstate"
  }

}

# ── Helm이 EKS에 붙도록 설정 ──
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}