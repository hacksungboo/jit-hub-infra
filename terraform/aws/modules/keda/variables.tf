variable "release_name" {
  type        = string
  default     = "keda"
  description = "Helm release name for KEDA"
}

variable "namespace" {
  type        = string
  default     = "keda"
  description = "Kubernetes namespace for KEDA"
}

