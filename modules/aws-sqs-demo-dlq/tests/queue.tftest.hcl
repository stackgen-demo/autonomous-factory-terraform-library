mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-west-2:123456789012:checkout-sandbox-dlq"
      url = "https://sqs.us-west-2.amazonaws.com/123456789012/checkout-sandbox-dlq"
    }
  }
}

variables {
  queue_name  = "checkout-sandbox-dlq"
  kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  tags = {
    Environment = "sandbox"
  }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = aws_sqs_queue.this.name == var.queue_name && !aws_sqs_queue.this.fifo_queue
    error_message = "The requested standard queue name must be preserved."
  }

  assert {
    condition     = aws_sqs_queue.this.kms_master_key_id == var.kms_key_arn
    error_message = "The queue must use the supplied customer-managed KMS key ARN."
  }

  assert {
    condition     = aws_sqs_queue.this.message_retention_seconds == 1209600
    error_message = "Default retention must be 14 days."
  }

  assert {
    condition     = aws_sqs_queue.this.tags["Environment"] == "sandbox"
    error_message = "Queue tags must be propagated."
  }

  assert {
    condition     = output.queue_arn == aws_sqs_queue.this.arn && output.queue_url == aws_sqs_queue.this.url
    error_message = "Outputs must expose the queue ARN and URL."
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.tls_only.policy).Statement[0].Effect == "Deny" && jsondecode(aws_sqs_queue_policy.tls_only.policy).Statement[0].Condition.Bool["aws:SecureTransport"] == "false" && jsondecode(aws_sqs_queue_policy.tls_only.policy).Statement[0].Resource == output.queue_arn
    error_message = "The queue policy must deny insecure transport on this queue."
  }
}

run "retention_override" {
  command = plan

  variables {
    message_retention_seconds = 604800
    tags                      = {}
  }

  assert {
    condition     = aws_sqs_queue.this.message_retention_seconds == 604800 && length(aws_sqs_queue.this.tags) == 0
    error_message = "Retention overrides and empty tags must be supported."
  }
}

run "reject_fifo_name" {
  command = plan

  variables {
    queue_name = "unsupported.fifo"
  }

  expect_failures = [var.queue_name]
}

run "reject_kms_alias" {
  command = plan

  variables {
    kms_key_arn = "arn:aws:kms:us-west-2:123456789012:alias/aws/sqs"
  }

  expect_failures = [var.kms_key_arn]
}

run "reject_excessive_retention" {
  command = plan

  variables {
    message_retention_seconds = 1209601
  }

  expect_failures = [var.message_retention_seconds]
}

run "reject_fractional_retention" {
  command = plan

  variables {
    message_retention_seconds = 60.5
  }

  expect_failures = [var.message_retention_seconds]
}

run "aws_v5_consumer" {
  command = apply

  module {
    source = "./tests/fixtures/aws-v5"
  }

  assert {
    condition     = output.queue_arn == "arn:aws:sqs:us-west-2:123456789012:checkout-sandbox-dlq" && output.queue_url == "https://sqs.us-west-2.amazonaws.com/123456789012/checkout-sandbox-dlq"
    error_message = "The consumer fixture pinned to AWS 5.100.0 must expose the mocked queue outputs."
  }
}
