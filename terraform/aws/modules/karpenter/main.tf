resource "helm_release" "karpenter" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true

  # OCI 레지스트리라서 username/password가 필요함 (일반 https 차트와 다름)
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = var.ecr_username
  repository_password = var.ecr_password

  chart   = "karpenter"
  version = "v0.32.0"

  # 값이 런타임에 결정되므로 file()이 아니라 templatefile()로 치환
  values = [
    templatefile("${path.module}/values.yaml", {
      irsa_role_arn      = var.irsa_role_arn
      cluster_name       = var.cluster_name
      cluster_endpoint   = var.cluster_endpoint
      interruption_queue = var.interruption_queue
    })
  ]
}