# shared/modules/ingress-nginx/variables.tf

variable "namespace" {
  type    = string
  default = "ingress-nginx"
}

variable "chart_version" {
  type    = string
  default = "4.11.3"
}

variable "service_type" {
  type    = string
}

variable "replica_count" {
  type    = number
}