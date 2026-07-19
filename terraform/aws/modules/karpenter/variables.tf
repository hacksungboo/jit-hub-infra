variable "release_name" {
  type    = string
  default = "karpenter"
}

variable "namespace" {
  type    = string
  default = "karpenter"
}

# ── ECR Public 차트 다운로드용 ──
variable "ecr_username" {
  type = string
}

variable "ecr_password" {
  type      = string
  sensitive = true
}

# ── Karpenter 설정값 ──
variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type        = string
  description = "새 노드가 클러스터에 조인할 때 접속할 주소"
}

variable "irsa_role_arn" {
  type        = string
  description = "Karpenter Pod이 사용할 IAM Role ARN"
}

variable "interruption_queue" {
  type        = string
  description = "Spot 중단 알림 SQS 큐 이름"
}