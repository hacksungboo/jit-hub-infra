variable "cluster_name" {}
variable "cluster_version" {}
variable "vpc_id" {}
variable "subnet_ids" {}
variable "vpc_cidr" {}

variable "node_groups" {
  type = any
}

variable "additional_node_security_group_rules" {
  type    = any
  default = {}
}