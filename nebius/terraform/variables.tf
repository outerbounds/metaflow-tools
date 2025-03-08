locals {
  # Keep these constant after initial "terraform apply"
  storage_container_name = "metaflow-storage-container"

  metaflow_datastore_sysroot_nebius = "s3://${local.storage_container_name}/tf-full-stack-sysroot"
  kubernetes_cluster_name = "metaflow-${terraform.workspace}"
  database_server_name = "psql-metaflow-${terraform.workspace}"
  storage_account_name = "stmetaflow${terraform.workspace}"

  # Changeable after initial "terraform apply" (e.g. image upgrades, secret rotation)
  metadata_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.3"
  metaflow_ui_static_service_image = "public.ecr.aws/outerbounds/metaflow_ui:v1.1.4"
  metaflow_ui_backend_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.3"
  metaflow_kubernetes_secret_name = "metaflow-nebius-storage-credentials"

  # Forever constants
  metaflow_database_server_admin_login = "metaflow"
  metaflow_db_name = "metaflow"
  metaflow_db_password = "metaflow" # DB is private, accessible only within vnet.
  metaflow_db_port = 5432

  # Airflow Related Options
  airflow_version = "2.10.4"
  airflow_frenet_secret = "myverysecretvalue"

  # Nebius constants
  nebius_s3_endpoint = "https://storage.eu-north1.nebius.cloud"
}

variable "deploy_argo" {
  type = bool
  default = true
}

variable "deploy_airflow" {
  type = bool
  default = false # Not supported
}

variable "tenant_id" {
  type        = string
  description = "The ID of your tenant, provided by the Nebius AI team"
}

variable "project_id" {
  type        = string
  description = "The ID of your project, provided by the Nebius AI team"
}

# Helm
variable "iam_token" {
  description = "Token for Helm provider authentication."
  type        = string
}

variable "vpc_subnet_id" {
  description = "The ID of the subnet to deploy the cluster into."
  type        = string
}

variable "aws_access_key_id" {
  description = "AWS access key id from console"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret access key from console"
  type        = string
}