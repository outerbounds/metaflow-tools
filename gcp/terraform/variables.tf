resource "random_id" "database_server_name_suffix" {
  byte_length = 4
  keepers = {
    db_generation_number = var.db_generation_number
  }
}

locals {

  database_server_name_prefix = "psql-metaflow-${terraform.workspace}"
  database_server_name        = "${local.database_server_name_prefix}-${random_id.database_server_name_suffix.hex}"
  kubernetes_cluster_name     = "gke-metaflow-${terraform.workspace}"
  zone                        = "${var.region}-a"

  storage_bucket_name           = "storage-${var.org_prefix}-metaflow-${terraform.workspace}"
  metaflow_datastore_sysroot_gs = "gs://${local.storage_bucket_name}/tf-full-stack-sysroot"

  airflow_logs_bucket_path = "gs://${local.storage_bucket_name}/airflow/logs"

  metaflow_ui_static_service_image  = "public.ecr.aws/outerbounds/metaflow_ui:latest"
  metaflow_ui_backend_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:latest"
  metadata_service_image            = "public.ecr.aws/outerbounds/metaflow_metadata_service:latest"
  # TODO gsa-metaflow-workload-id-<workspace>
  metaflow_workload_identity_gsa_name = "gsa-metaflow-${terraform.workspace}"

  metaflow_workload_identity_ksa_name = "ksa-metaflow"
  service_account_key_file            = "${path.root}/metaflow_gsa_key_${terraform.workspace}.json"

  airflow_version = "2.5.0"
}

variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "org_prefix" {
  type = string
}

variable "oauth_clientid" {
  type    = string
  default = ""
}

variable "oauth_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "db_generation_number" {
  type    = number
  default = 0
}

variable "deploy_argo" {
  type    = bool
  default = true
}

variable "deploy_airflow" {
  type    = bool
  default = false
}

variable "airflow_frenet_secret" {
  type    = string
  default = "myverysecretvalue"
}

variable "max_cpu" {
  type    = number
  default = 200
}

variable "max_memory" {
  type    = number
  default = 400
}
