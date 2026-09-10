variable "queue_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "service_account_name" {
  type = string
}

variable "pod_identity_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

