resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version
  namespace  = var.namespace
  create_namespace = true
  timeout    = 600

  set {
    name  = "controller.replicaCount"
    value = var.replica_count
  }

  set {
    name  = "controller.service.type"
    value = var.service_type
  }

  set {
    name  = "controller.publishService.enabled"
    value = var.service_type == "LoadBalancer" ? "true" : "false"
  }

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }
}