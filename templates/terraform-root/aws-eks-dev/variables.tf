variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "cluster_name" {
  type    = string
  default = "ai-sre-demo"
}

variable "namespace" {
  type    = string
  default = "autonomous-factory-dev"
}

variable "service_account_name" {
  type    = string
  default = "autonomous-factory-demo"
}
