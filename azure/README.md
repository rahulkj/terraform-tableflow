Terraform Azure environment
---

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

    `subscription_id` / `tenant_id` - your azure into
    `sp_application_id` - the value of Microsoft Entra ID from the confluent cloud UI

- Finally run the terraform commands
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```
