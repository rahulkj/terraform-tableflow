# Subscription / tenant
variable "subscription_id" {
  description = "Azure subscription ID where resources will be created."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
}

# If you want to run Terraform using a SP explicitly, uncomment in provider:
# variable "client_id" {
#   description = "Client ID of the service principal used by Terraform (not the SP being created)."
#   type        = string
# }
#
# variable "client_secret" {
#   description = "Client secret of the service principal used by Terraform."
#   type        = string
#   sensitive   = true
# }

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
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

variable "databricks_access_connector_name" {
  description = "Name of the Azure Databricks Access Connector."
  type        = string
}

# Databricks workspace auth
variable "databricks_host" {
  description = "Databricks workspace URL, e.g. https://<region>.azuredatabricks.net"
  type        = string
}

variable "databricks_token" {
  description = "Databricks personal access token"
  type        = string
  sensitive   = true
}

# ADLS container
variable "storage_container_name" {
  description = "Name of the ADLS Gen2 container to create in the storage account."
  type        = string
  default     = "data"
}

# Databricks Unity Catalog integration objects
variable "databricks_storage_credential_name" {
  description = "Name of the Databricks storage credential."
  type        = string
  default     = "adls-storage-credential"
}

variable "databricks_external_location_name" {
  description = "Name of the Databricks external location for ADLS Gen2."
  type        = string
  default     = "adls-external-location"
}

variable "databricks_catalog_name" {
  description = "Name of the Databricks Unity Catalog catalog."
  type        = string
  default     = "adls_catalog"
}

variable "databricks_account_host" {
  description = "Databricks account control plane URL, e.g. https://accounts.cloud.databricks.com"
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID (UUID)."
  type        = string
}

variable "databricks_account_token" {
  description = "Databricks PAT with account admin permissions."
  type        = string
  sensitive   = true
}

variable "databricks_sp_display_name" {
  description = "Display name for the Databricks service principal used for catalog/external location access."
  type        = string
  default     = "uc-adls-sp"
}