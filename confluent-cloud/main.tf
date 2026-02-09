terraform {
  required_version = ">= 1.3.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# -----------------------------------------
# Create Confluent environment
# -----------------------------------------
resource "confluent_environment" "env" {
  display_name      = var.environment_name
  stream_governance {
    package = var.stream_governance_package
  }
}

# -----------------------------------------
# Basic Kafka cluster on Azure / centralus
# -----------------------------------------
resource "confluent_kafka_cluster" "cluster" {
  display_name = var.kafka_cluster_name
  availability = var.availability

  cloud  = var.cloud
  region = var.region

  basic {}

  environment {
    id = confluent_environment.env.id
  }
}

# -----------------------------------------
# Service account for Datagen connector
# -----------------------------------------
resource "confluent_service_account" "connector_sa" {
  display_name = var.connector_service_account_name
  description  = "Service account for Datagen Source connector producing to '${var.topic_name}'"
}

# Give this SA CloudClusterAdmin on the cluster (simplest for demo)
resource "confluent_role_binding" "connector_sa_cluster_admin" {
  principal = "User:${confluent_service_account.connector_sa.id}"

  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cluster.rbac_crn

  depends_on = [
    confluent_kafka_cluster.cluster,
    confluent_service_account.connector_sa
  ]
}

# -----------------------------------------
# Kafka API key for connector SA (cluster scoped)
# -----------------------------------------
resource "confluent_api_key" "connector_kafka" {
  display_name = var.connector_kafka_api_key_display_name
  description  = "Kafka API key for Datagen connector service account"

  owner {
    id          = confluent_service_account.connector_sa.id
    api_version = confluent_service_account.connector_sa.api_version
    kind        = confluent_service_account.connector_sa.kind
  }

  managed_resource {
    api_version = confluent_kafka_cluster.cluster.api_version
    kind        = "Cluster"
    id          = confluent_kafka_cluster.cluster.id

    environment {
      id = confluent_environment.env.id
    }
  }

  depends_on = [
    confluent_kafka_cluster.cluster,
    confluent_role_binding.connector_sa_cluster_admin
  ]
}

# -----------------------------------------
# Kafka topic: stocks
# -----------------------------------------
resource "confluent_kafka_topic" "stocks" {
  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  topic_name       = var.topic_name
  partitions_count = 6

  rest_endpoint = confluent_kafka_cluster.cluster.rest_endpoint

  # Use the connector SA’s Kafka API key for admin ops
  credentials {
    key    = confluent_api_key.connector_kafka.id
    secret = confluent_api_key.connector_kafka.secret
  }

  depends_on = [
    confluent_api_key.connector_kafka
  ]
}

# -----------------------------------------
# Datagen Source connector: STOCK_TRADES -> stocks (AVRO)
# -----------------------------------------
resource "confluent_connector" "datagen_stocks" {
  environment {
    id = confluent_environment.env.id
  }

  kafka_cluster {
    id = confluent_kafka_cluster.cluster.id
  }

  status = "RUNNING"

  # Non-sensitive config
  config_nonsensitive = {
    "connector.class"    = "DatagenSource"
    "name"               = var.datagen_connector_name

    # Kafka auth: use the generated Kafka API key
    "kafka.auth.mode"    = "KAFKA_API_KEY"
    "kafka.api.key"      = confluent_api_key.connector_kafka.id

    # Target topic
    "kafka.topic"        = var.topic_name

    # Datagen dataset and format
    "quickstart"         = "STOCK_TRADES"
    "output.data.format" = "AVRO"

    # Runtime
    "tasks.max"          = "1"
  }

  # Sensitive config
  config_sensitive = {
    "kafka.api.secret" = confluent_api_key.connector_kafka.secret
  }

  depends_on = [
    confluent_kafka_topic.stocks
  ]
}

# -----------------------------------------
# Outputs
# -----------------------------------------
output "environment_id" {
  value = confluent_environment.env.id
}

output "kafka_cluster_id" {
  value = confluent_kafka_cluster.cluster.id
}

output "stocks_topic_name" {
  value = confluent_kafka_topic.stocks.topic_name
}

output "datagen_connector_id" {
  value = confluent_connector.datagen_stocks.id
}

output "connector_kafka_api_key" {
  value       = confluent_api_key.connector_kafka.id
  description = "Kafka API key used by the Datagen connector."
}

output "connector_kafka_api_secret" {
  value       = confluent_api_key.connector_kafka.secret
  sensitive   = true
  description = "Kafka API secret used by the Datagen connector."
}