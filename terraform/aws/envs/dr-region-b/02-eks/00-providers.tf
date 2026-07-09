# terraform/02-eks/00-providers.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "terraform_remote_state" "network" {

  backend = "local"
  # s3 사용시
  # backend = "s3"

  config = {
    path = "../01-network/terraform.tfstate"
  }
}
