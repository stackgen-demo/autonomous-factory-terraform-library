variable "enable_consumer_access" {
  description = "Allow the application to receive and delete messages from this queue. Producer-only access remains the default."
  type        = bool
  default     = false
  nullable    = false
}

variable "require_consumer_access" {
  description = "Require consumer access for a worker; rejects configurations with enable_consumer_access disabled. Does not grant permissions by itself."
  type        = bool
  default     = false
  nullable    = false
}
