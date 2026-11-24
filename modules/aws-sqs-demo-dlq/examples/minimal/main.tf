terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

variable "queue_name" {
  description = "Sandbox dead-letter queue name."
  type        = string
}

variable "kms_key_arn" {
  description = "Existing customer-managed KMS key ARN in us-west-2."
  type        = string
}

module "dlq" {
  source = "../.."

  queue_name  = var.queue_name
  kms_key_arn = var.kms_key_arn
  tags = {
    Environment = "sandbox"
    Service     = "checkout"
  }
}

output "queue_arn" {
  description = "Dead-letter queue ARN."
  value       = module.dlq.queue_arn
}

output "queue_url" {
  description = "Dead-letter queue URL."
  value       = module.dlq.queue_url
}
