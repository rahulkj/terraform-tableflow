terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # If you’re running as a service principal, you can also set:
  # client_id       = var.client_id
  # client_secret   = var.client_secret
}

provider "azuread" {
  tenant_id = var.tenant_id
}

# Workspace-level provider (you already added something like this)
provider "databricks" {
  alias = "workspace"

  host  = var.databricks_host    # workspace URL
  token = var.databricks_token   # PAT scoped to workspace
}

# Account-level provider for managing service principals
provider "databricks" {
  alias     = "account"
  host      = var.databricks_account_host    # e.g. https://accounts.cloud.databricks.com
  account_id = var.databricks_account_id
  token     = var.databricks_account_token   # PAT with account admin permissions
}

# Service principal in Databricks Account
resource "databricks_service_principal" "uc_sp" {
  provider = databricks.account

  display_name = var.databricks_sp_display_name
  active       = true
}

# Generate a random secret for the service principal
resource "random_password" "uc_sp_secret" {
  length  = 32
  special = true
}

# Attach that secret to the Databricks service principal
resource "databricks_service_principal_secret" "uc_sp_secret" {
  provider = databricks.account

  service_principal_id = databricks_service_principal.uc_sp.id
  secret               = random_password.uc_sp_secret.result
}

# Permissions on the external location
resource "databricks_grants" "uc_sp_external_location" {
  provider          = databricks.workspace
  external_location = databricks_external_location.adls_external_location.name

  grant {
    principal = databricks_service_principal.uc_sp.application_id
    privileges = [
      "ALL_PRIVILEGES",
      "MANAGE",
      "CREATE_EXTERNAL_TABLE",
      "CREATE_EXTERNAL_VOLUME",
      "READ_FILES",
      "WRITE_FILES",
      "CREATE_MANAGED_STORAGE",
      "EXTERNAL_USE_LOCATION"
    ]
  }

  depends_on = [
    databricks_external_location.adls_external_location,
    databricks_service_principal.uc_sp
  ]
}

# Permissions on the catalog
resource "databricks_grants" "uc_sp_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.adls_catalog.name

  grant {
    principal = databricks_service_principal.uc_sp.application_id
    privileges = [
      "ALL_PRIVILEGES",
      "USE_CATALOG",
      "CREATE_SCHEMA",
      "USE_SCHEMA",
      "EXTERNAL_USE_SCHEMA",
      "CREATE_TABLE"
    ]
  }

  depends_on = [
    databricks_catalog.adls_catalog,
    databricks_service_principal.uc_sp
  ]
}

#-----------------------------------------
# Resource group
#-----------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

#-----------------------------------------
# Storage account
#-----------------------------------------
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  kind                     = "StorageV2"

  is_hns_enabled           = true            # <-- add this for ADLS Gen2
  allow_blob_public_access = false
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "main" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

#-----------------------------------------
# Databricks workspace (Premium SKU)
#-----------------------------------------
resource "azurerm_databricks_workspace" "main" {
  name                = var.databricks_workspace_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "premium"

  tags = var.tags
}

#-----------------------------------------
# Service principal (from provided app / client ID)
#-----------------------------------------
# Assumes the application (app registration) already exists in AAD,
# and you provide its application (client) ID via var.sp_application_id.
resource "azuread_service_principal" "sp" {
  application_id = var.sp_application_id
}

#-----------------------------------------
# Role assignments for the service principal
#-----------------------------------------

# 1) Reader on the resource group (so SP can read RG / workspace metadata)
resource "azurerm_role_assignment" "sp_reader_rg" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.sp.object_id
}

# 2) Storage Blob Data Contributor on the storage account
resource "azurerm_role_assignment" "sp_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.sp.object_id
}

#-----------------------------------------
# Databricks Access Connector
#-----------------------------------------
resource "azurerm_databricks_access_connector" "main" {
  name                = var.databricks_access_connector_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

#-----------------------------------------
# Grant Storage Blob Data Contributor to Access Connector
#-----------------------------------------
resource "azurerm_role_assignment" "dac_storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
}


#Databricks
resource "databricks_storage_credential" "adls_credential" {
  provider = databricks.workspace

  name = var.databricks_storage_credential_name

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.main.id
  }

  comment = "Storage credential for ADLS Gen2 via Access Connector"

  depends_on = [
    azurerm_databricks_access_connector.main,
    azurerm_role_assignment.dac_storage_blob_contributor
  ]
}

resource "databricks_external_location" "adls_external_location" {
  provider = databricks.workspace

  name            = var.databricks_external_location_name
  url             = "abfss://${azurerm_storage_container.main.name}@${azurerm_storage_account.main.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.adls_credential.id
  comment         = "External location for ${azurerm_storage_account.main.name}/${azurerm_storage_container.main.name}"

  force_destroy = true

  depends_on = [
    databricks_storage_credential.adls_credential
  ]
}

resource "databricks_catalog" "adls_catalog" {
  provider = databricks.workspace

  name         = var.databricks_catalog_name
  storage_root = databricks_external_location.adls_external_location.url
  comment      = "Catalog backed by ADLS Gen2 storage account ${azurerm_storage_account.main.name}"

  force_destroy = true

  depends_on = [
    databricks_external_location.adls_external_location
  ]
}

#-----------------------------------------
# Optional: outputs
#-----------------------------------------
output "databricks_access_connector_id" {
  value = azurerm_databricks_access_connector.main.id
}

output "databricks_access_connector_principal_id" {
  value = azurerm_databricks_access_connector.main.identity[0].principal_id
}

#-----------------------------------------
# Optional outputs
#-----------------------------------------
output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.main.id
}

output "storage_account_id" {
  value = azurerm_storage_account.main.id
}

output "service_principal_object_id" {
  value = azuread_service_principal.sp.object_id
}

output "databricks_service_principal_application_id" {
  description = "Databricks service principal application (client) ID used as Unity Catalog principal."
  value       = databricks_service_principal.uc_sp.application_id
}

output "databricks_service_principal_id" {
  description = "Internal Databricks service principal ID."
  value       = databricks_service_principal.uc_sp.id
}

output "databricks_service_principal_secret" {
  description = "Generated secret for the Databricks service principal (handle with care; stored in state)."
  value       = random_password.uc_sp_secret.result
  sensitive   = true
}