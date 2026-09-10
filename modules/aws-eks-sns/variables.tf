variable "topic_name" {
  type = string
}

variable "pod_identity_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
