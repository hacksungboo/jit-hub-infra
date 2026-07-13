# shared/modules/cloudflared/connector/variables.tf

variable "namespace" {
  type    = string
  default = "cloudflared"
}

variable "create_namespace" {
  type    = bool
  default = true
}

variable "secret_name" {
  type    = string
  default = "cloudflared-token"
}

variable "tunnel_token" {
  type      = string
  sensitive = true
}

variable "replicas" {
  type        = number
  description = "eks-a=1, onprem=0, eks-b=0 (평시 기준)"
}

variable "cloudflared_image" {
  type    = string
  default = "cloudflare/cloudflared:2024.11.0"
}