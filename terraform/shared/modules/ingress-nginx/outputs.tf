# shared/modules/ingress-nginx/outputs.tf

output "controller_service_name" {
  value = "ingress-nginx-controller.${var.namespace}.svc.cluster.local"
}