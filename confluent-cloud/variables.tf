# -----------------------------------------------------
# Confluent Cloud management credentials (Cloud API key)
# -----------------------------------------------------
variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (Cloud API ID) with resource-management permissions."
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret."
  type        = string
  sensitive   = true
}

# -----------------------------------------------------
# Create environment
# -----------------------------------------------------
variable "environment_name" {
  description = "Confluent Cloud environment Name"
  type        = string
}

variable "stream_governance_package" {
  description = "Confluent Cloud stream governance package"
  type        = string
}

# -----------------------------------------------------
# Cluster settings
# -----------------------------------------------------
variable "kafka_cluster_name" {
  description = "Display name for the Kafka cluster."
  type        = string
  default     = "azure-centralus-basic"
}

variable "availability" {
  description = "Specify the availability needed for this cluster"
  type        = string
}

variable "cloud" {
  description = "Specify the IaaS where this cluster need to ne created"
  type        = string
}

variable "region" {
  description = "Specify the region where this cluster will be created"
  type        = string
}

# -----------------------------------------------------
# Topic + Datagen
# -----------------------------------------------------
variable "topic_name" {
  description = "Kafka topic name where Datagen will produce stock trades."
  type        = string
  default     = "stocks"
}

variable "datagen_connector_name" {
  description = "Name of the Datagen connector."
  type        = string
  default     = "datagen_stocks"
}

# -----------------------------------------------------
# Service account & Kafka API key naming
# -----------------------------------------------------
variable "connector_service_account_name" {
  description = "Display name for the Datagen connector service account."
  type        = string
  default     = "datagen-stocks-sa"
}

variable "connector_kafka_api_key_display_name" {
  description = "Display name for the Kafka API key used by the Datagen connector."
  type        = string
  default     = "datagen-stocks-kafka-api-key"
}

variable "azure_tenant_id" {
  description = "Azure tenant id."
  type        = string
}