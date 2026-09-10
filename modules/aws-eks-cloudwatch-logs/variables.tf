variable "log_group_name" {
  type = string
}

variable "pod_identity_role_arn" {
  type = string
}

variable "retention_in_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
