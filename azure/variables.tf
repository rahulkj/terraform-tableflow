# Subscription / tenant
variable "subscription_id" {
  description = "Azure subscription ID where resources will be created."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

# Location / naming
variable "location" {
  description = "Azure region for the resource group, Databricks workspace, and storage account."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

variable "databricks_workspace_name" {
  description = "Name of the Azure Databricks workspace."
  type        = string
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3–24 lower-case alphanumeric chars)."
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "storage_account_name must be 3–24 characters of only lowercase letters and numbers."
  }
}

variable "storage_container_name" {
  description = "Name of the ADLS Gen2 container to create in the storage account."
  type        = string
  default     = "data"
}

# Service principal being granted access
variable "sp_application_id" {
  description = "Application (client) ID of the existing Azure AD app registration for which to create a service principal and assign roles."
  type        = string
}

# Tags
variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default = {
    Environment = "demo"
    ManagedBy   = "Terraform"
  }
}

variable "databricks_access_connector_name" {
  description = "Name of the Azure Databricks Access Connector."
  type        = string
}
