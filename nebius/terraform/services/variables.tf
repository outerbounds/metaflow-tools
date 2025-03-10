variable "kubernetes_cluster_name" {
    type = string
}

variable "metaflow_db_host" {
  type = string
}
variable "metaflow_db_port" {
  type = number
}
variable "metaflow_db_user" {
  type = string
}
variable "metaflow_db_password" {
  type = string
}
variable "metaflow_db_name" {
  type = string
}
variable "metadata_service_image" {
  type = string
}

variable "metaflow_ui_static_service_image" {
  type = string
}

variable "metaflow_ui_backend_service_image" {
  type = string
}

variable "metaflow_datastore_sysroot_nebius" {
  type = string
}

variable "nebius_s3_endpoint" {
  type = string
}

variable "metaflow_storage_account_name" {
  type = string
}

variable "nebius_storage_credentials" {
  type = map
}

variable "metaflow_kubernetes_secret_name"{
  type = string
}

variable "argo_version" {
  type = string
}
variable "airflow_version" {
  type = string
}

variable "airflow_frenet_secret" {
  type = string
}

variable "deploy_argo" {
  type = bool
}

variable "deploy_airflow" {
  type = bool
}

