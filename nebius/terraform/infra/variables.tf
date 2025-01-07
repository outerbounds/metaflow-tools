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

variable "deploy_airflow" {
  type = bool
}

variable "project_id" {
  type        = string
  description = "The ID of your project, provided by the Nebius AI team"
}

variable "tenant_id" {
  type        = string
  description = "The ID of your tenat, provided by the Nebius AI team"
}

variable "nebius_network_id" {
  type        = string
  description = "nebius_network_id"
}
variable "nebius_sub_network_id" {
  type        = string
  description = "nebius_sub_network_id"
}