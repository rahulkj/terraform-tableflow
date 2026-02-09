# terraform-tableflow
---

How to use this repo
---

## Clone the repo
> git clone https://github.com/rahulkj/terraform-tableflow

> cd terraform-tableflow

## Step 1: Terraform Confluent Cloud

- Switch to `confluent-cloud` directory
    > cd confluent-cloud

- Copy the `terraform.tfvars_template` to `terraform.tfvars`
    > cp terraform.tfvars_template terraform.tfvars

- Update the values in `terraform.tfvars`
    ```
    # Cloud API key with resource-management permissions
    confluent_cloud_api_key    = ""
    confluent_cloud_api_secret = ""

    # Existing environment
    environment_name = "<PREFIX>-demo-env"
    stream_governance_package = "ESSENTIALS"

    # Optional overrides
    kafka_cluster_name     = "azure-centralus-basic"
    topic_name             = "stocks"
    datagen_connector_name = "datagen_stocks"

    availability = "SINGLE_ZONE"
    cloud  = "AZURE"
    region = "centralus"

    connector_service_account_name = "<PREFIX>-cluster-admin-sa"
    connector_kafka_api_key_display_name = "<PREFIX>-kafka-sa"

    azure_tenant_id = ""
    ```

    - `confluent_cloud_api_key` / `confluent_cloud_api_secret` > Generate these API Keys the confluent cloud, that has `Cloud resource management` as the scope
    - `<PREFIX>` - to your desired unique letters
    - `azure_tenant_id` - your azure tenant id


- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

## Step 2: Manual steps

- Login to confluent cloud
- Create the tableflow integration with azure using Microsoft Entra ID, where you will create entra id app, and capture this id and its going to be the value for `sp_application_id`.

## Step 3: Terraform Azure environment

- Switch to `confluent-cloud` directory
    > cd confluent-cloud

- Copy the `terraform.tfvars_template` to `terraform.tfvars`
    > cp terraform.tfvars_template terraform.tfvars

- Update the values in `terraform.tfvars`
    ```
    # terraform.tfvars
    subscription_id           = ""
    tenant_id                 = ""
    resource_group_name       = "<PREFIX>-dbx-demo-rg"
    location                  = "centralus"
    databricks_workspace_name = "<PREFIX>-dbx-workspace"
    storage_account_name      = "<PREFIX>tfdbxstorageacc"
    storage_container_name    = "tableflow"

    sp_application_id = "<confluent-cloud-microsoft-entra-id>"

    databricks_access_connector_name   = "<PREFIX>-dbx-demo-access-connector"
    ```

    - `subscription_id` / `tenant_id` - your azure into
    - `sp_application_id` - the value of Microsoft Entra ID from the confluent cloud UI

- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve -var="sp_application_id=$(cd ../confluent-cloud && terraform output -raw azure_app_id)"
    ```

## Step 4: Terraform Databricks environment

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

    - `databricks_host` - output from the azure terraform  `$(cd azure && terraform output -raw databricks_workspace_url)`
    - `databricks_token` - generate a token for yourself from the databricks UI. YOUR NAME > Settings > User > Developer > Access tokens > Manage > Generate new token
    - `databricks_sp_application_id` - service principal app id. YOUR NAME > Settings > Workspace admin > Identity and access > Service principals > Manage > Add service principal
    - `external_location_abfss_url` - output from the azure terraform `$(cd azure && terraform output -raw abfss_storage_location)`
    - `access_connector_id` - output from the azure terraform `$(cd azure && terraform output -raw databricks_access_connector_id)`

- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

## Step 5: Enable tableflow on Confluent Cloud
- Follow the docs to complete the provider integration and connecting to the unity catalog
- Enable tableflow on the topic and supply the details there. You would need
   - `storage_account_name` - output from azure terraform - `cd azure && terraform output -raw azure_storage_account_name`
   - `storage_container_name` - output from azure terraform - `cd azure && terraform output -raw azure_storage_container_name`

## Step 6: Integrate with the unity catalog
- Click on tableflow, and select Catalog Integration
- Select Unity Catalog
- Fill in the values from the azure and databricks terraform output
    - Databricks workspace url - `cd azure && terraform output -raw databricks_workspace_url`
    - Client ID - You generated this from your databricks service principal tab
    - Client Secret - You generated this from your databricks service principal tab
    - Unity catalog name - `cd databricks && terraform output -raw catalog_name`


## References: 
- https://docs.confluent.io/cloud/current/topics/tableflow/how-to-guides/catalog-integration/integrate-with-unity-catalog.html