# --- 1. Tunnel Secret 생성 -------------------------------------------
resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

# --- 2. Cloudflare Tunnel 본체 생성 -----------------------------------
resource "cloudflare_tunnel" "vmware_tunnel" {
  account_id = var.cloudflare_account_id
  name       = "vmware-local-tunnel"
  secret     = base64encode(random_password.tunnel_secret.result)
}

# --- 3. DNS CNAME 레코드 생성 -----------------------------------------
resource "cloudflare_record" "vmware_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# 모니터링 수집용 서브도메인 DNS 레코드
resource "cloudflare_record" "prometheus_ingest_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "prometheus-ingest"
  content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "loki_ingest_dns" {
  zone_id = var.cloudflare_zone_id
  name    = "loki-ingest"
  content = "${cloudflare_tunnel.vmware_tunnel.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# --- 4. Tunnel 라우팅 규칙 (Ingress Controller 매핑) -------------------
resource "cloudflare_tunnel_config" "vmware_config" {
  account_id = cloudflare_tunnel.vmware_tunnel.account_id
  tunnel_id  = cloudflare_tunnel.vmware_tunnel.id

  config {
    # EKS → 온프레미스 Prometheus remote_write 수신
    ingress_rule {
      hostname = "prometheus-ingest.${var.domain_name}"
      service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
    }
    # EKS → 온프레미스 Loki 로그 수신
    ingress_rule {
      hostname = "loki-ingest.${var.domain_name}"
      service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
    }
    # 메인 앱 트래픽
    ingress_rule {
      hostname = var.domain_name
      service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}

# --- 5. null_resource를 통한 Ansible 실행 (cloudflared 파드 기동) ------
resource "null_resource" "install_cloudflared_pod" {
  depends_on = [
    cloudflare_tunnel_config.vmware_config,
    cloudflare_record.vmware_dns
  ]
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i localhost, -c local ${path.module}/playbook-kubectl.yml --extra-vars 'tunnel_token=${cloudflare_tunnel.vmware_tunnel.tunnel_token}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${path.module}/deploy-cloudflared.yaml && kubectl delete secret tunnel-credentials --ignore-not-found=true"
  }
}

# -------------------------------------------------------------------------------
# K8s 코어 인프라 설치 (Ingress 및 ArgoCD)
# -------------------------------------------------------------------------------

# Ingress Nginx 설치
resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.11.0"
  namespace        = "ingress-nginx"
  create_namespace = true
}

# ArgoCD 설치
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.1.2"
  namespace        = "argocd"
  create_namespace = true
  values = [
    file("${path.module}/argocd/my-values.yaml")
  ]
    set {
    name  = "configs.secret.argocdServerAdminPassword"
    # htpasswd (bcrypt) 형태로 변환하여 주입
    value = bcrypt("jithub12") 
  }
  depends_on = [helm_release.ingress_nginx]
}

# ArgoCD 프로젝트 구성
resource "kubectl_manifest" "argocd_project" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.module}/../../../gitops/argocd/projects/jit-hub-project.yaml")
}

# Spoke(온프레미스 로컬) 클러스터 등록
resource "kubectl_manifest" "onprem_cluster" {
  depends_on = [helm_release.argocd]
  yaml_body  = file("${path.module}/../../../gitops/argocd/clusters/onprem-cluster.yaml")
}
