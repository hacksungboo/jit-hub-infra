# =============================================================================
# terraform/utils/harbor-tunnel/outputs.tf
# =============================================================================

output "harbor_tunnel_id" {
  description = "생성된 Harbor 전용 터널 ID"
  value       = module.harbor_tunnel.tunnel_id
}

output "harbor_tunnel_name" {
  description = "Harbor 전용 터널 이름"
  value       = module.harbor_tunnel.tunnel_name
}

output "harbor_url" {
  description = "외부에서 접근하는 Harbor URL (HTTPS)"
  value       = "https://${var.harbor_subdomain}.${var.domain_name}"
}

output "harbor_connector_namespace" {
  description = "Harbor 터널 connector 가 배포된 네임스페이스"
  value       = module.harbor_connector.namespace
}
