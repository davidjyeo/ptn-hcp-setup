variable "organization" {
  description = "The name of the TFC organization"
  type        = string
}

variable "project_name" {
  description = "Base name of the project"
  type        = string
}

variable "environments" {
  description = "List of environment names"
  type        = list(string)
  default     = ["dev", "test", "stage", "prod"]
}

variable "tfc_azure_provider_auth" {
  description = "Authentication flag for Azure provider."
  type        = bool
  default     = true
}
