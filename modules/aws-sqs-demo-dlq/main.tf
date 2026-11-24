resource "aws_sqs_queue" "this" {
  name                      = var.queue_name
  fifo_queue                = false
  kms_master_key_id         = var.kms_key_arn
  message_retention_seconds = var.message_retention_seconds
  tags                      = var.tags
}

# Deny unencrypted transport without granting any queue permissions.
resource "aws_sqs_queue_policy" "tls_only" {
  queue_url = aws_sqs_queue.this.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = aws_sqs_queue.this.arn
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}
