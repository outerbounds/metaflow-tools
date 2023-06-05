variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "project" {
  type = string
}

variable "enable_ingress" {
  type    = bool
  default = false
}

variable "enable_iap" {
  type    = bool
  default = false
}

variable "oauth_clientid" {
  type = string
}

variable "oauth_secret" {
  type      = string
  sensitive = true
}

variable "database_server_name" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "metaflow_workload_identity_gsa_name" {
  type = string
}

variable "storage_bucket_name" {
  type = string
}

variable "service_account_key_file" {
  type = string
}

variable "max_cpu" {
  type    = number
  default = 200
}

variable "max_memory" {
  type    = number
  default = 400
}
