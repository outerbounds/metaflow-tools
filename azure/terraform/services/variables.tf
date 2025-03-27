variable "kubeconfig" {
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

variable "metaflow_datastore_sysroot_azure" {
  type = string
}

variable "metaflow_storage_account_name" {
  type = string
}

variable "metaflow_azure_storage_blob_service_endpoint" {
  type = string
}

variable "azure_storage_credentials" {
  type = map(any)
}

variable "metaflow_kubernetes_secret_name" {
  type = string
}

variable "airflow_version" {
  type = string
}

variable "airflow_frenet_secret" {
  type = string
}

variable "argo_workflows_version" {
  type = string
}

variable "argo_events_version" {
  type = string
}

variable "deploy_argo" {
  type = bool
}

variable "deploy_argo_events" {
  type = bool
}

variable "deploy_airflow" {
  type = bool
}

