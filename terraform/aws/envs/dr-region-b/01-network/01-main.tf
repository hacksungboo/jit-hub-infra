# terraform/01-network/01-main.tf

# ---------------------------------------------------------
# 1. 네트워크 계층 (VPC 생성)
# ---------------------------------------------------------
# EKS가 동작할 기본 네트워크 환경을 구성
# 퍼블릭/프라이빗 서브넷 분리 (ALB / Node 분리 목적)
module "vpc" {
  source = "../../../modules/vpc"

  name             = "eks-vpc"
  # vpc 네트워크 대역
  cidr             = "10.10.0.0/16"
  # 사용할 AZ (고가용성)
  azs              = ["ap-northeast-1a", "ap-northeast-1c"]
  # EKS 워커 노드 배치되는 private 서브넷
  private_subnets  = ["10.10.1.0/24", "10.10.2.0/24"]
  # LoadBalancer / NAT 게이트웨이 사용하는 public 서브넷
  public_subnets   = ["10.10.101.0/24", "10.10.102.0/24"]
}

## 사용할 region 및 AZ (고가용성)
#   - KR(서울)      ap-northeast-2  2a, 2b, 2c, 2d 
#   - JP(도쿄)      ap-northeast-1  1a, 1c, 1d 
#   - JP(오사카)    ap-northeast-3  3a, 3b, 3c 
#   - SG(싱가포르)  ap-southeast-1  1a, 2b, 1c
#   - AU(시드니)    ap-southeast-2  2a, 2b, 2c, 2d 