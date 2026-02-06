# -----------------------------------------------------
# Databricks account/workspace details
# -----------------------------------------------------
variable "databricks_host" {
  description = "Databricks workspace URL (e.g. https://adb-XXXXXXXX.XX.azuredatabricks.net)."
  type        = string
}

variable "databricks_token" {
  description = "Databricks workspace personal access token (PAT) used by Terraform."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------
# Databricks service principal details
# -----------------------------------------------------
variable "databricks_sp_application_id" {
  description = "Application (client) ID of the Databricks service principal to grant permissions to."
  type        = string
}

# -----------------------------------------------------
# Catalog configuration
# -----------------------------------------------------
variable "catalog_name" {
  description = "Name of the Unity Catalog catalog to create."
  type        = string
}

# -----------------------------------------------------
# External storage configuration
# -----------------------------------------------------
variable "external_location_abfss_url" {
  description = "ABFSS URL for the external storage location (output from azure terraform: abfss_storage_location)."
  type        = string
}

variable "storage_credential_name" {
  description = "Name for the Databricks storage credential."
  type        = string
  default     = "adls-access-cred"
}

variable "external_location_name" {
  description = "Name for the Databricks external location."
  type        = string
  default     = "adls-external-location"
}

# -----------------------------------------------------
# Azure Access Connector input (from azurerm_databricks_access_connector)
# -----------------------------------------------------
variable "access_connector_id" {
  description = "Resource ID of the Azure Databricks Access Connector to use (output from azure terraform: databricks_access_connector_id)."
  type        = string
}