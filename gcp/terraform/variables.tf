resource random_id database_server_name_suffix {
  byte_length = 4
  keepers = {
    db_generation_number = var.db_generation_number
  }
}

locals {

  database_server_name_prefix = "metaflow-database-server-${terraform.workspace}"
  database_server_name = "${local.database_server_name_prefix}-${random_id.database_server_name_suffix.hex}"
  kubernetes_cluster_name = "metaflow-kubernetes-${terraform.workspace}"
  region = "us-west2"
  zone = "us-west2-a"

  storage_bucket_name = "${var.org_prefix}-metaflow-storage-bucket-${terraform.workspace}"
  metaflow_datastore_sysroot_gs = "gs://${local.storage_bucket_name}/tf-full-stack-sysroot"

  metaflow_ui_static_service_image = "public.ecr.aws/outerbounds/metaflow_ui:v1.1.4"
  metaflow_ui_backend_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.3"
  metadata_service_image = "public.ecr.aws/outerbounds/metaflow_metadata_service:2.3.3"
  metaflow_workload_identity_gsa_name = "sa-mf-k8s-wi-${terraform.workspace}"

  metaflow_workload_identity_ksa_name = "metaflow-service-account"
  service_account_key_file            = "${path.root}/metaflow_gsa_key_${terraform.workspace}.json"
}

variable project {
  type = string
}

variable org_prefix {
  type = string
}

variable db_generation_number {
  type = number
  default = 0
}