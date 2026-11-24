variable "enable_consumer_access" {
  description = "Allow the application to receive and delete messages from this queue. Producer-only access remains the default."
  type        = bool
  default     = false
  nullable    = false
}

variable "require_consumer_access" {
  description = "Require consumer permissions for checkout workers. When true, enable_consumer_access must also be true; producer-only callers remain unchanged by default."
  type        = bool
  default     = false
  nullable    = false
}
