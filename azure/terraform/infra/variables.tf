variable "location" {
  type = string
}

variable "metaflow_resource_group_name" {
  type = string
}

variable "metaflow_database_server_admin_login" {
  description = "Admin login for Metaflow database server"
  type        = string
}
variable "metaflow_database_server_admin_password" {
  description = "Admin password for Metaflow database server"
  type        = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_container_name" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "database_server_name" {
  type = string
}

variable "service_principal_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "db_subnet_name" {
  type = string
}

variable "k8s_subnet_name" {
  type = string
}

variable "deploy_airflow" {
  type = bool
}