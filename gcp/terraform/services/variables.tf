variable "metaflow_ui_static_service_image" {
  type = string
}

variable "metaflow_datastore_sysroot_gs" {
  type = string
}

variable "metaflow_db_name" {
  type = string
}

variable "metaflow_db_user" {
  type = string
}

variable "metaflow_db_host" {
  type = string
}

variable "metaflow_ui_backend_service_image" {
  type = string
}

variable "metaflow_db_port" {
  type = string
}

variable "metaflow_db_password" {
  type = string
}

variable "project" {
  type = string
}

variable "db_connection_name" {
  type = string
}

variable "metaflow_workload_identity_gsa_name" {
  type = string
}

variable "metaflow_workload_identity_gsa_id" {
  type = string
}

variable "metaflow_workload_identity_ksa_name" {
  type = string
}

variable "metadata_service_image" {
  type = string
}

variable "kubeconfig_path" {
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

variable "airflow_logs_bucket_path" {
  type = string
}

