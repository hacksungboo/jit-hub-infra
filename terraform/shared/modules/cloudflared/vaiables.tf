# shared/modules/cloudflared/tunnel/variables.tf

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "tunnel_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "dns_records" {
  description = "서브도메인 목록. 루트 도메인은 \"@\"로 표기"
  type        = list(string)
  default     = ["@"]
}

variable "ingress_rules" {
  description = "hostname -> service 매핑. 여러 서브도메인을 라우팅할 때 사용"
  type = list(object({
    hostname = string
    service  = string
  }))
}