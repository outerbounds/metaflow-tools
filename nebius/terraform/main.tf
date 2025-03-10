terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    nebius = {
      source  = "terraform-provider.storage.eu-north1.nebius.cloud/nebius/nebius"
      version = ">= 0.3.10"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

data "nebius_mk8s_v1_cluster" "default" {
  depends_on = [module.infra] # refresh cluster state before reading
  parent_id  = var.iam_project_id
  name       = local.kubernetes_cluster_name
}

data "nebius_msp_postgresql_v1alpha1_cluster" "default" {
  depends_on = [module.infra] # refresh cluster state before reading
  parent_id  = var.iam_project_id
  name       = local.database_server_name
}

data "nebius_storage_v1_bucket" "default" {
  depends_on = [module.infra] # refresh cluster state before reading
  parent_id  = var.iam_project_id
  name       = local.storage_container_name
}

provider "kubernetes" {
  host                   = data.nebius_mk8s_v1_cluster.default.status.control_plane.endpoints.public_endpoint
  cluster_ca_certificate = data.nebius_mk8s_v1_cluster.default.status.control_plane.auth.cluster_ca_certificate
  token                  = var.iam_token
}

provider "helm" {
  kubernetes {
    host                   = data.nebius_mk8s_v1_cluster.default.status.control_plane.endpoints.public_endpoint
    cluster_ca_certificate = data.nebius_mk8s_v1_cluster.default.status.control_plane.auth.cluster_ca_certificate
    token                  = var.iam_token
  }
}



data "nebius_vpc_v1_network" "default" {
  parent_id = var.iam_project_id
  name      = "default-network"
}

module "infra" {
  source                                  = "./infra"
  iam_project_id                          = var.iam_project_id
  iam_tenant_id                           = var.iam_tenant_id
  vpc_subnet_id                           = var.vpc_subnet_id
  metaflow_database_server_admin_login    = local.metaflow_database_server_admin_login
  metaflow_database_server_admin_password = local.metaflow_db_password
  storage_container_name                  = local.storage_container_name
  storage_account_name                    = local.storage_account_name
  kubernetes_cluster_name                 = local.kubernetes_cluster_name
  database_server_name                    = local.database_server_name
  deploy_airflow                          = var.deploy_airflow
  nebius_network_id                       = data.nebius_vpc_v1_network.default.id
}

module "services" {
  depends_on = [module.infra]
  source     = "./services"

  metadata_service_image            = local.metadata_service_image
  metaflow_ui_static_service_image  = local.metaflow_ui_static_service_image
  metaflow_ui_backend_service_image = local.metaflow_ui_backend_service_image
  metaflow_datastore_sysroot_nebius = local.metaflow_datastore_sysroot_nebius
  metaflow_storage_account_name     = data.nebius_storage_v1_bucket.default.name
  metaflow_db_port                  = local.metaflow_db_port
  metaflow_db_name                  = local.metaflow_db_name
  metaflow_db_host                  = data.nebius_msp_postgresql_v1alpha1_cluster.default.status.connection_endpoints.private_read_write
  metaflow_db_user                  = local.metaflow_database_server_admin_login
  metaflow_db_password              = local.metaflow_db_password
  kubernetes_cluster_name           = local.kubernetes_cluster_name
  metaflow_kubernetes_secret_name   = local.metaflow_kubernetes_secret_name
  nebius_s3_endpoint                = local.nebius_s3_endpoint

  nebius_storage_credentials = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  }

  deploy_airflow = var.deploy_airflow
  deploy_argo    = var.deploy_argo
  argo_version   = local.argo_version

  airflow_version       = local.airflow_version
  airflow_frenet_secret = local.airflow_frenet_secret
}
// https://github.com/Netflix/metaflow/issues/158
