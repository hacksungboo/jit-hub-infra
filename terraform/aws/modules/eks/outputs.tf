output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# Karpenter 등 IRSA를 쓰는 애드온이 이 ARN을 필요로 함
output "oidc_provider_arn" {
  description = "IRSA용 OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}