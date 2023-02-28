locals {
  # Keep these constant after initial "terraform apply"



  storage_container_name           = "metaflow-storage-container"
  metaflow_datastore_sysroot_azure = "${local.storage_container_name}/tf-full-stack-sysroot"
  location                         = "westus"
  metaflow_resource_group_name     = "rg-metaflow-${terraform.workspace}-${local.location}"
  # MUST be globally unique (entire Azure). Would recommend user to add a meaningful prefix.
  kubernetes_cluster_name = "aks-${var.org_prefix}-metaflow-${terraform.workspace}"
  # This MUST be globally unique (entire Azure). Pick a meaningful and unique value for org_prefix
  database_server_name = "psql-${var.org_prefix}-metaflow-${terraform.workspace}"
  # This MUST be globally unique (entire Azure). Pick a meaningful and unique value for org_prefix
  storage_account_name           = "st${var.org_prefix}metaflow${terraform.workspace}"
  storage_service_principal_name = "Metaflow storage service principal (${terraform.workspace})"
  virtual_network_name           = "vnet-${var.org_prefix}-metaflow-${local.location}-${terraform.workspace}"
  db_subnet_name                 = "snet-${var.org_prefix}-metaflow-db-${local.location}-${terraform.workspace}"
  k8s_subnet_name                = "snet-${var.org_prefix}-metaflow-k8s-${local.location}-${terraform.workspace}"

  # Changeable after initial "terraform apply" (e.g. image upgrades, secret rotation)
  metadata_service_image            = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.6"
  metaflow_ui_static_service_image  = "public.ecr.aws/outerbounds/metaflow_ui:v1.2.4"
  metaflow_ui_backend_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.6"
  metaflow_kubernetes_secret_name   = "metaflow-azure-storage-credentials"

  # Forever constants
  metaflow_database_server_admin_login = "metaflow"
  metaflow_db_name                     = "metaflow"
  metaflow_db_password                 = "metaflow" # DB is private, accessible only within vnet.
  metaflow_db_port                     = 5432

  # Changeable Airflow Related Options
  # See https://airflow.apache.org/docs/apache-airflow/stable/release_notes.html
  airflow_version       = "2.3.3"
  airflow_frenet_secret = "myverysecretvalue"

  # Changeable Argo Related Options
  # In non-production/test environments these versions may be set as "latest".  If this repo is 
  # used as a starting point for your production k8s cluster used for Metaflow, then it is a best
  # practice to set specific version numbers here that are tracked in your own version control repository. 
  # See https://github.com/argoproj/argo-workflows/releases
  argo_workflows_version = "v3.4.4"
  # See https://github.com/argoproj/argo-events/releases
  argo_events_version = "v1.7.6"
}

# You MUST set this to ensure global (Azure-wide) uniqueness of:
# - DB server name
# - storage account name
# Ask Azure about it... :)
#
variable "org_prefix" {
  type = string
}

variable "deploy_argo" {
  type    = bool
  default = true
}

variable "deploy_argo_events" {
  type    = bool
  default = true
}

variable "deploy_airflow" {
  type    = bool
  default = false
}
