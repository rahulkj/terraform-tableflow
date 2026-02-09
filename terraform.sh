#!/bin/bash -e

BASE_DIR=$(dirname "$0")
DIR=$(readlink -f "$BASE_DIR")

if [ -f "$DIR/.envrc" ]; then
    echo "Loading environment variables from .envrc"
    source "$DIR/.envrc"
else
    echo "Error: .envrc file not found in $DIR. Please create it with the required environment variables."
    echo "copy the .env_template file to .envrc and update the values accordingly."
    exit 1
fi

setup() {
    echo "Setting up Confluent Cloud infrastructure..."

    pushd "$DIR/confluent-cloud"
        terraform init
        terraform apply -auto-approve
    popd

    echo "Setting up Azure infrastructure..."
    export TF_VAR_sp_application_id="$(cd $DIR/confluent-cloud && terraform output -raw azure_app_id)"

    pushd "$DIR/azure"
        terraform init
        terraform apply -auto-approve
    popd

    echo "Completing Confluent Cloud Tableflow Integration setup"
    pushd "$DIR/confluent-cloud"
        terraform init
        terraform apply -auto-approve
    popd

    echo "Setting up Azure Databricks infrastructure..."
    export TF_VAR_databricks_host="$(cd $DIR/azure && terraform output -raw databricks_workspace_url)"
    export TF_VAR_external_location_abfss_url="$(cd $DIR/azure && terraform output -raw abfss_storage_location)"
    export TF_VAR_access_connector_id="$(cd $DIR/azure && terraform output -raw databricks_access_connector_id)"

    pushd "$DIR/databricks"
        terraform init
        terraform apply -auto-approve
    popd

    echo "Required values for the next steps:"
    echo "Azure storage account name: $TF_VAR_storage_account_name"
    echo "Container name: $TF_VAR_storage_container_name"
    
    echo "Databricks Unity Catalog Integration Name: $PREFIX-unity-catalog-integration"
    echo "Databricks Host: https://$TF_VAR_databricks_host"
    echo "Databricks Client ID: $TF_VAR_databricks_sp_application_id"
    echo "Databricks Client Secret: $TF_VAR_databricks_sp_application_secret"
    echo "Databricks Catalog Name: $TF_VAR_catalog_name"


    echo "Setup complete!"
}

destory() {
    export TF_VAR_sp_application_id="$(cd $DIR/confluent-cloud && terraform output -raw azure_app_id)"
    export TF_VAR_databricks_host="$(cd $DIR/azure && terraform output -raw databricks_workspace_url)"
    export TF_VAR_external_location_abfss_url="$(cd $DIR/azure && terraform output -raw abfss_storage_location)"
    export TF_VAR_access_connector_id="$(cd $DIR/azure && terraform output -raw databricks_access_connector_id)"

    echo "Destroying Azure Databricks infrastructure..."
    pushd "$DIR/databricks"
        terraform destroy -auto-approve
    popd

    echo "Destroying Azure infrastructure..."
    pushd "$DIR/azure"
        terraform destroy -auto-approve
    popd

    echo "Destroying Confluent Cloud infrastructure..."
    pushd "$DIR/confluent-cloud"
        terraform destroy -auto-approve
    popd

    echo "Destroy complete!"
}

usage() {
    echo "Usage: $0 [setup|destroy]"
    exit 1
}

# Specify the command you wish to execeute

case "$1" in
    setup)
        setup
        ;;
    destroy)
        destory
        ;;
    *)
        usage
        ;;
esac