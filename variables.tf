variable "region" {
  description = "AWS region"
  type = string
}

variable "account_id" {
  description = "The AWS account ID"
  type = string
}

variable "prefect_api_key" {
  description = "API key for retrivial of data"
  type = string
  sensitive = true
}

variable "prefect_account_id" {
  description = "Prefect Cloud account ID"
  type        = string
}

variable "prefect_workspace_id" {
  description = "Prefect Cloud workspace ID"
  type        = string
}

variable "prefect_account_url" {
  description = "Prefect Cloud account URL"
  type        = string
  default     = "https://api.prefect.cloud"
}
