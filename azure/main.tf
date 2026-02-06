terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
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
}

provider "azuread" {
  tenant_id = var.tenant_id
}

#-----------------------------------------
# Resource group
#-----------------------------------------
resource "azurerm_resource_group" "main" {
  name = var.resource_group_name

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

  is_hns_enabled                = true # <-- add this for ADLS Gen2
  min_tls_version               = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "main" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.main.id
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

  managed_resource_group_name = var.databricks_workspace_name

  tags = var.tags
}

#-----------------------------------------
# Service principal (from provided app / client ID)
#-----------------------------------------
# Assumes the application (app registration) already exists in AAD,
# and you provide its application (client) ID via var.sp_application_id.
resource "azuread_service_principal" "sp" {
  client_id = var.sp_application_id
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
resource "azurerm_role_assignment" "dac_storage_account_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "dac_storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "dac_eventgrid_subs_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "dac_storage_queue_data_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_databricks_access_connector.main.identity[0].principal_id
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

output "databricks_access_connector_id" {
  value = azurerm_databricks_access_connector.main.id
}

output "databricks_access_connector_principal_id" {
  value = azurerm_databricks_access_connector.main.identity[0].principal_id
}

output "tenant_id" {
  value = var.tenant_id
}

output "abfss_storage_location" {
  value = "abfss://${var.storage_container_name}@${var.storage_account_name}.dfs.core.windows.net/"
}
