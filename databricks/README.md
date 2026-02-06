Terraform Databricks environment
---

- Switch to `databricks` directory
    > cd databricks

- Copy the `terraform.tfvars_template` to `terraform.tfvars`
    > cp terraform.tfvars_template terraform.tfvars

- Update the values in `terraform.tfvars`
    ```
    # Databricks workspace (account) details
    databricks_host  = 
    databricks_token = 

    # Service principal details
    databricks_sp_application_id = 

    # Catalog + storage configuration
    catalog_name                = "<PREFIX>-terraform-catalog"
    external_location_abfss_url = 

    storage_credential_name = "<PREFIX>-terraform-storage-cred"
    external_location_name  = "<PREFIX>-terraform-external-location"

    # Azure Access Connector ID (from ARM / azurerm_databricks_access_connector)
    access_connector_id = 
    ```

    `databricks_host` - in azure, access the Azure Databricks resource that got created in the earlier step. Capture the url from your browser - https://adb-740XXXXXX.19.azuredatabricks.net/
    `databricks_token` - generate a token for yourself from the databricks UI. YOUR NAME > Settings > User > Developer > Access tokens > Manage > Generate new token
    `databricks_sp_application_id` - service principal app id. YOUR NAME > Settings > Workspace admin > Identity and access > Service principals > Manage > Add service principal
    `external_location_abfss_url` - output from the azure terraform `abfss_storage_location`
    `access_connector_id` - output from the azure terraform `databricks_access_connector_id`

- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```