resource "aws_sqs_queue" "dead_letter" {
  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn
  tags                      = var.tags
}

resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  visibility_timeout_seconds = 30
  kms_master_key_id          = var.kms_key_arn
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = 5
  })
  tags = var.tags
}

data "aws_iam_policy_document" "application_queue_access" {
  statement {
    actions = concat(
      ["sqs:GetQueueAttributes", "sqs:SendMessage"],
      var.enable_consumer_access ? ["sqs:ReceiveMessage", "sqs:DeleteMessage"] : []
    )
    resources = [aws_sqs_queue.this.arn]
  }

  dynamic "statement" {
    for_each = var.kms_key_arn == null ? [] : [var.kms_key_arn]
    content {
      actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_role_policy" "application_queue_access" {
  name   = "${var.queue_name}-access"
  role   = element(reverse(split("/", var.pod_identity_role_arn)), 0)
  policy = data.aws_iam_policy_document.application_queue_access.json

  lifecycle {
    precondition {
      condition     = !var.require_consumer_access || var.enable_consumer_access
      error_message = "Checkout workers requiring consumer access must set enable_consumer_access = true."
    }
  }
}

resource "aws_eks_pod_identity_association" "application" {
  cluster_name    = var.cluster_name
  namespace       = var.namespace
  service_account = var.service_account_name
  role_arn        = var.pod_identity_role_arn
}

