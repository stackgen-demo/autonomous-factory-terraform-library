terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "checkout" {
  source = "../../.."

  queue_name              = "orders"
  cluster_name            = "checkout-sandbox"
  namespace               = "checkout"
  service_account_name    = "checkout-worker"
  pod_identity_role_arn   = "arn:aws:iam::123456789012:role/checkout-worker"
  kms_key_arn             = "arn:aws:kms:us-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  enable_consumer_access  = true
  require_consumer_access = true
}

output "queue_arn" {
  value = module.checkout.queue_arn
}
