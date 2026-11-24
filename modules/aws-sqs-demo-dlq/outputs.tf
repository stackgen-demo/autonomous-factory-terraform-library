output "queue_arn" {
  description = "ARN of the dead-letter queue; use as deadLetterTargetArn in a source queue's redrive policy."
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.this.url
}
