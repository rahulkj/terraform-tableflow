Terraform Confluent Cloud
---

## Terraform Confluent Cloud
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
    ```

    `confluent_cloud_api_key` / `confluent_cloud_api_secret` > Generate these API Keys the confluent cloud, that has `Cloud resource management` as the scope
    `<PREFIX>` - to your desired unique letters
- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

## Manual steps
- Login to confluent cloud
- Create the tableflow integration with azure using Microsoft Entra ID, where you will create entra id app, and capture this id and its going to be the value for `sp_application_id`.