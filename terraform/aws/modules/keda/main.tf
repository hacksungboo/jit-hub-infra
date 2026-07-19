resource "helm_release" "keda" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://kedacore.github.io/charts"
  chart            = "keda"
  version          = "2.14.0"

  values = [
    file("${path.module}/values.yaml")
  ]

}
