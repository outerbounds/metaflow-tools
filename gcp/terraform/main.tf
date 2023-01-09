terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.31.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {
  provider   = google-beta
  depends_on = [module.infra]
}

# Defer reading the cluster data until the GKE cluster exists.
data "google_container_cluster" "default" {
  provider   = google-beta
  location   = local.zone
  project    = var.project
  name       = local.kubernetes_cluster_name
  depends_on = [module.infra]
}

data "google_sql_database_instance" "default" {
  provider   = google-beta
  project    = var.project
  name       = local.database_server_name
  depends_on = [module.infra]

}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.default.endpoint}"
  token = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.default.master_auth[0].cluster_ca_certificate,
  )
}
provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.default.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
    # token is required here and we remove `client_certificate` / `client_key` because it results in this error like : 
    # `Error: unable to build kubernetes objects from release manifest: unknown`
    # More notes on this issue can be found here : https://github.com/hashicorp/terraform-provider-helm/issues/513
  }
}

# This will be used for invoking kubectl re: Argo installation
resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig_template.yaml", {
    cluster_name  = data.google_container_cluster.default.name
    endpoint      = data.google_container_cluster.default.endpoint
    cluster_ca    = data.google_container_cluster.default.master_auth[0].cluster_ca_certificate
    cluster_token = data.google_client_config.default.access_token
  })
  filename = "${path.root}/kubeconfig"
}

module "infra" {
  source                              = "./infra"
  region                              = local.region
  zone                                = local.zone
  project                             = var.project
  database_server_name                = local.database_server_name
  kubernetes_cluster_name             = local.kubernetes_cluster_name
  storage_bucket_name                 = local.storage_bucket_name
  metaflow_workload_identity_gsa_name = local.metaflow_workload_identity_gsa_name
  service_account_key_file            = local.service_account_key_file
}

module "services" {
  depends_on                          = [module.infra, data.google_container_cluster.default]
  source                              = "./services"
  metaflow_ui_static_service_image    = local.metaflow_ui_static_service_image
  metaflow_ui_backend_service_image   = local.metaflow_ui_backend_service_image
  metaflow_datastore_sysroot_gs       = local.metaflow_datastore_sysroot_gs
  airflow_logs_bucket_path            = local.airflow_logs_bucket_path
  metaflow_db_host                    = "localhost"
  metaflow_db_name                    = "metaflow"
  metaflow_db_user                    = "metaflow"
  metaflow_db_password                = "metaflow"
  metaflow_db_port                    = 5432
  project                             = var.project
  db_connection_name                  = data.google_sql_database_instance.default.connection_name
  metaflow_workload_identity_gsa_id   = module.infra.metaflow_workload_identity_gsa_id
  metaflow_workload_identity_gsa_name = local.metaflow_workload_identity_gsa_name
  metaflow_workload_identity_ksa_name = local.metaflow_workload_identity_ksa_name
  metadata_service_image              = local.metadata_service_image
  kubeconfig_path                     = local_file.kubeconfig.filename
  deploy_airflow                      = var.deploy_airflow
  deploy_argo                         = var.deploy_argo
  airflow_version                     = local.airflow_version
  airflow_frenet_secret               = local.airflow_frenet_secret
}