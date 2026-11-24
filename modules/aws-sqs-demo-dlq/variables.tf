variable "queue_name" {
  description = "Name of the standard dead-letter queue (1-80 letters, numbers, hyphens or underscores). FIFO queues are not supported."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,80}$", var.queue_name))
    error_message = "queue_name must contain 1-80 letters, numbers, hyphens or underscores; FIFO names are not supported."
  }
}

variable "kms_key_arn" {
  description = "ARN of an existing customer-managed KMS key in the queue's region. Key aliases and the AWS-managed SQS key are not accepted."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^arn:(aws|aws-us-gov|aws-cn|aws-iso|aws-iso-b|aws-iso-e|aws-iso-f):kms:[a-z0-9-]+:[0-9]{12}:key/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|mrk-[0-9a-fA-F]{32})$", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN (UUID or multi-region key ID), not an alias or bare key ID."
  }
}

variable "message_retention_seconds" {
  description = "Message retention in seconds; defaults to the SQS maximum of 14 days. Use a retention period longer than the source queue's."
  type        = number
  default     = 1209600
  nullable    = false

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600 && floor(var.message_retention_seconds) == var.message_retention_seconds
    error_message = "message_retention_seconds must be an integer between 60 and 1209600 (14 days)."
  }
}

variable "tags" {
  description = "Tags to apply to the dead-letter queue. Provider default_tags also apply."
  type        = map(string)
  default     = {}
  nullable    = false
}
