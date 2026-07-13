# shared/modules/cloudflared/tunnel/main.tf

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  dns_records_full = [
    for r in var.dns_records : r == "@" ? var.domain_name : "${r}.${var.domain_name}"
  ]
}

resource "random_password" "tunnel_secret" {
  length  = 64
  special = false
}

resource "cloudflare_tunnel" "this" {
  account_id = var.cloudflare_account_id
  name       = var.tunnel_name
  secret     = base64encode(random_password.tunnel_secret.result)
}

resource "cloudflare_record" "this" {
  for_each = toset(local.dns_records_full)

  zone_id = var.cloudflare_zone_id
  name    = each.value
  content = "${cloudflare_tunnel.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_tunnel_config" "this" {
  account_id = cloudflare_tunnel.this.account_id
  tunnel_id  = cloudflare_tunnel.this.id

  config {
    dynamic "ingress_rule" {
      for_each = var.ingress_rules
      content {
        hostname = ingress_rule.value.hostname
        service  = ingress_rule.value.service
      }
    }
    ingress_rule {
      service = "http_status:404"
    }
  }
}