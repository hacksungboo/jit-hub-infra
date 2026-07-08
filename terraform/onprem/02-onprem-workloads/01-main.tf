# observability 배포
resource "kubectl_manifest" "infra_applicationset" {

  yaml_body = file("${path.module}/../../../gitops/argocd/applicationsets/infra-applicationset.yaml")
}


# 3. 실제 비즈니스 MSA 앱 배포를 위한 App-ApplicationSet 가동
resource "kubectl_manifest" "app_applicationset" {

  yaml_body = file("${path.module}/../../../gitops/argocd/applicationsets/app-applicationset.yaml")
}
