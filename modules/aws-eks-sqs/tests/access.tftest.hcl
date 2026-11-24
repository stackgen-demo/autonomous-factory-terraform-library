mock_provider "aws" {
  # Supply syntactically valid mock JSON; policy assertions inspect configured statements.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-west-2:123456789012:orders"
      url = "https://sqs.us-west-2.amazonaws.com/123456789012/orders"
    }
  }
}

variables {
  queue_name            = "orders"
  cluster_name          = "checkout-sandbox"
  namespace             = "checkout"
  service_account_name  = "checkout-worker"
  pod_identity_role_arn = "arn:aws:iam::123456789012:role/checkout-worker"
}

run "producer_only_default" {
  command = apply

  assert {
    condition     = length(data.aws_iam_policy_document.application_queue_access.statement) == 1 && toset(one(data.aws_iam_policy_document.application_queue_access.statement).actions) == toset(["sqs:GetQueueAttributes", "sqs:SendMessage"])
    error_message = "Default access must contain only the two existing producer actions."
  }
  assert {
    condition     = toset(one(data.aws_iam_policy_document.application_queue_access.statement).resources) == toset([aws_sqs_queue.this.arn])
    error_message = "Producer access must be scoped to the orders queue."
  }
  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == null && aws_sqs_queue.dead_letter.kms_master_key_id == null
    error_message = "The optional KMS key must remain unset by default."
  }
}

run "consumer_opt_in" {
  command = apply
  variables {
    enable_consumer_access = true
  }
  assert {
    condition     = length(data.aws_iam_policy_document.application_queue_access.statement) == 1 && toset(one(data.aws_iam_policy_document.application_queue_access.statement).actions) == toset(["sqs:GetQueueAttributes", "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"])
    error_message = "Opt-in must add exactly ReceiveMessage and DeleteMessage to existing access."
  }
  assert {
    condition     = toset(one(data.aws_iam_policy_document.application_queue_access.statement).resources) == toset([aws_sqs_queue.this.arn])
    error_message = "Consumer permissions must target only the orders queue."
  }
}

run "encrypted_producer" {
  command = apply
  variables {
    kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  }
  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn && aws_sqs_queue.dead_letter.kms_master_key_id == var.kms_key_arn
    error_message = "Both queues must retain the deployed customer-managed KMS key."
  }
  assert {
    condition     = length(data.aws_iam_policy_document.application_queue_access.statement) == 2 && length([for s in data.aws_iam_policy_document.application_queue_access.statement : s if toset(s.actions) == toset(["sqs:GetQueueAttributes", "sqs:SendMessage"]) && toset(s.resources) == toset([aws_sqs_queue.this.arn])]) == 1
    error_message = "Encrypted default must remain producer-only and queue-scoped."
  }
  assert {
    condition     = length([for s in data.aws_iam_policy_document.application_queue_access.statement : s if toset(s.actions) == toset(["kms:Decrypt", "kms:GenerateDataKey"]) && toset(s.resources) == toset([var.kms_key_arn])]) == 1
    error_message = "Preserve exactly the deployed key-scoped KMS actions."
  }
}

run "encrypted_consumer" {
  command = apply
  variables {
    enable_consumer_access = true
    kms_key_arn            = "arn:aws:kms:us-west-2:123456789012:key/11111111-2222-3333-4444-555555555555"
  }
  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn && aws_sqs_queue.dead_letter.kms_master_key_id == var.kms_key_arn
    error_message = "Consumer opt-in must not change encryption on either queue."
  }
  assert {
    condition     = length(data.aws_iam_policy_document.application_queue_access.statement) == 2 && length([for s in data.aws_iam_policy_document.application_queue_access.statement : s if toset(s.actions) == toset(["sqs:GetQueueAttributes", "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"]) && toset(s.resources) == toset([aws_sqs_queue.this.arn])]) == 1
    error_message = "Encrypted opt-in must add only the requested queue-scoped actions."
  }
  assert {
    condition     = length([for s in data.aws_iam_policy_document.application_queue_access.statement : s if toset(s.actions) == toset(["kms:Decrypt", "kms:GenerateDataKey"]) && toset(s.resources) == toset([var.kms_key_arn])]) == 1
    error_message = "Consumer opt-in must preserve key-scoped KMS permissions."
  }
  assert {
    condition     = aws_sqs_queue.this.visibility_timeout_seconds == 30 && aws_sqs_queue.dead_letter.message_retention_seconds == 1209600 && aws_sqs_queue.dead_letter.name == "orders-dlq" && jsondecode(aws_sqs_queue.this.redrive_policy).maxReceiveCount == 5 && jsondecode(aws_sqs_queue.this.redrive_policy).deadLetterTargetArn == aws_sqs_queue.dead_letter.arn
    error_message = "Keep deployed visibility timeout, DLQ retention/name and redrive settings."
  }
  assert {
    condition     = aws_eks_pod_identity_association.application.role_arn == var.pod_identity_role_arn && aws_eks_pod_identity_association.application.service_account == var.service_account_name && aws_eks_pod_identity_association.application.namespace == var.namespace && aws_eks_pod_identity_association.application.cluster_name == var.cluster_name && aws_iam_role_policy.application_queue_access.role == "checkout-worker"
    error_message = "Keep existing application identity binding and policy attachment."
  }
}

run "checkout_consumer_required" {
  command = apply

  variables {
    require_consumer_access = true
    enable_consumer_access  = true
  }

  assert {
    condition     = toset(one(data.aws_iam_policy_document.application_queue_access.statement).actions) == toset(["sqs:GetQueueAttributes", "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage"])
    error_message = "A guarded checkout worker must retain producer and consumer permissions."
  }
}

run "checkout_consumer_disabled_rejected" {
  command = plan

  variables {
    require_consumer_access = true
    enable_consumer_access  = false
  }

  expect_failures = [aws_sqs_queue.this, aws_eks_pod_identity_association.application]
}

run "checkout_consumer_disabled_targeted_association_rejected" {
  command = plan

  plan_options {
    target = [aws_eks_pod_identity_association.application]
  }

  variables {
    require_consumer_access = true
    enable_consumer_access  = false
  }

  expect_failures = [aws_eks_pod_identity_association.application]
}
