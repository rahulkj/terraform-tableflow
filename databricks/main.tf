terraform {
  required_version = ">= 1.3.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.60"
    }
  }
}

# -------------------------------------------------------------------
# Databricks workspace provider (workspace-level)
#   - Uses workspace host + PAT provided by user
# -------------------------------------------------------------------
provider "databricks" {
  alias = "workspace"

  host  = var.databricks_host   # e.g. https://adb-XXXX.XX.azuredatabricks.net
  token = var.databricks_token  # workspace PAT
}

# -------------------------------------------------------------------
# Storage credential using Azure Databricks Access Connector
# -------------------------------------------------------------------
resource "databricks_storage_credential" "external_cred" {
  provider = databricks.workspace

  name = var.storage_credential_name

  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }

  comment = "Storage credential using Access Connector for ${var.external_location_abfss_url}"
}

# -------------------------------------------------------------------
# External location pointing at the ABFSS URL
# -------------------------------------------------------------------
resource "databricks_external_location" "external_loc" {
  provider = databricks.workspace

  name            = var.external_location_name
  url             = var.external_location_abfss_url  # e.g. abfss://data@account.dfs.core.windows.net/path/
  credential_name = databricks_storage_credential.external_cred.name
  comment         = "External location for ${var.external_location_abfss_url}"

  force_destroy = true

  depends_on = [
    databricks_storage_credential.external_cred
  ]
}

# -------------------------------------------------------------------
# Catalog backed by the same ABFSS storage root
# -------------------------------------------------------------------
resource "databricks_catalog" "catalog" {
  provider = databricks.workspace

  name         = var.catalog_name
  storage_root = var.external_location_abfss_url
  comment      = "Catalog backed by ${var.external_location_abfss_url}"

  force_destroy = true

  depends_on = [
    databricks_external_location.external_loc
  ]
}

# -------------------------------------------------------------------
# Grants: ALL_PRIVILEGES on external location to the service principal
# -------------------------------------------------------------------
resource "databricks_grants" "external_location_grants" {
  provider          = databricks.workspace
  external_location = databricks_external_location.external_loc.name

  grant {
    principal  = var.databricks_sp_application_id   # SP application/client ID
    privileges = [
      "CREATE_EXTERNAL_TABLE",
      "EXTERNAL_USE_LOCATION",
      "READ_FILES",
      "WRITE_FILES"
    ]
  }

  depends_on = [
    databricks_external_location.external_loc
  ]
}

# -------------------------------------------------------------------
# Grants: ALL_PRIVILEGES on catalog to the service principal
# -------------------------------------------------------------------
resource "databricks_grants" "catalog_grants" {
  provider = databricks.workspace
  catalog  = databricks_catalog.catalog.name

  grant {
    principal  = var.databricks_sp_application_id
    privileges = [
      "APPLY_TAG",
      "BROWSE",
      "CREATE_FUNCTION",
      "CREATE_MATERIALIZED_VIEW",
      "CREATE_MODEL",
      "CREATE_SCHEMA",
      "CREATE_TABLE",
      "CREATE_VOLUME",
      "EXTERNAL_USE_SCHEMA",
      "MODIFY",
      "READ_VOLUME",
      "SELECT",
      "USE_CATALOG",
      "USE_SCHEMA",
      "WRITE_VOLUME"
    ]
  }

  depends_on = [
    databricks_catalog.catalog
  ]
}

# -------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------
output "storage_credential_name" {
  description = "Name of the created Databricks storage credential."
  value       = databricks_storage_credential.external_cred.name
}

output "external_location_name" {
  description = "Name of the created Databricks external location."
  value       = databricks_external_location.external_loc.name
}

output "catalog_name" {
  description = "Name of the created Unity Catalog catalog."
  value       = databricks_catalog.catalog.name
}