variable "name" {
  description = "The project name to use for unique resource naming"
  default     = "s3backend"
  type        = string
}

variable "create" {
  description = "Create Module, defaults to true."
  default     = true
}

variable "principal_arns" {
  description = "A list of principal arns allowed to assume the IAM role"
  default     = null
  type        = list(string)
}

variable "force_destroy_state" {
  description = "Force destroy the s3 bucket containing state files?"
  default     = true
  type        = bool
}