terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

variable "queue_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "message_retention_seconds" {
  type    = number
  default = 1209600
}

module "dlq" {
  source = "../../.."

  queue_name                = var.queue_name
  kms_key_arn               = var.kms_key_arn
  message_retention_seconds = var.message_retention_seconds
  tags                      = var.tags
}

output "queue_arn" {
  value = module.dlq.queue_arn
}

output "queue_url" {
  value = module.dlq.queue_url
}
