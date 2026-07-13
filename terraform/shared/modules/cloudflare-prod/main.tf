# shared/modules/cloudflared/connector/main.tf
# cloudflared pod 배포 모듈
# (ArgoCD 이전 임시 모듈)

resource "kubernetes_namespace" "cloudflare" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "cloudflared_token" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace
  }
  type = "Opaque"
  data = {
    token = var.tunnel_token
  }

  depends_on = [kubernetes_namespace.cloudflare]
}

resource "kubernetes_deployment" "cloudflared" {
  metadata {
    name      = "cloudflared"
    namespace = var.namespace
    labels    = { app = "cloudflared" }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = { app = "cloudflared" }
    }

    template {
      metadata {
        labels = { app = "cloudflared" }
      }

      spec {
        container {
          name  = "cloudflared"
          image = var.cloudflared_image

          args = [
            "tunnel",
            "--no-autoupdate",
            "run",
            "--token",
            "$(TUNNEL_TOKEN)"
          ]

          env {
            name = "TUNNEL_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.cloudflared_token.metadata[0].name
                key  = "token"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_secret.cloudflared_token]
}