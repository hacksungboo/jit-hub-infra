# shared/modules/cloudflared/tunnel/outputs.tf

output "tunnel_id" {
  value = cloudflare_tunnel.this.id
}

output "tunnel_name" {
  value = cloudflare_tunnel.this.name
}

output "tunnel_token" {
  value     = cloudflare_tunnel.this.tunnel_token
  sensitive = true
}