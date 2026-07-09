# terraform/01-network/00-providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.8"
}

provider "aws" {
  region = "ap-northeast-1"
}

## 사용할 region 및 AZ (고가용성)
#   - KR(서울)      ap-northeast-2  2a, 2b, 2c, 2d 
#   - JP(도쿄)      ap-northeast-1  1a, 1c, 1d 
#   - JP(오사카)    ap-northeast-3  3a, 3b, 3c 
#   - SG(싱가포르)  ap-southeast-1  1a, 2b, 1c
#   - AU(시드니)    ap-southeast-2  2a, 2b, 2c, 2d 