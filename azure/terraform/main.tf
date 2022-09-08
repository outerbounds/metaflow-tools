terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.14.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}


data "azurerm_kubernetes_cluster" "default" {
  depends_on          = [module.infra]  # refresh cluster state before reading
  resource_group_name = local.metaflow_resource_group_name
  name                = local.kubernetes_cluster_name
}

data "azurerm_postgresql_flexible_server" "default" {
  depends_on          = [module.infra]  # refresh cluster state before reading
  resource_group_name = local.metaflow_resource_group_name
  name                = local.database_server_name
}

data "azurerm_storage_account" "default" {
  depends_on          = [module.infra]  # refresh cluster state before reading
  resource_group_name = local.metaflow_resource_group_name
  name                = local.storage_account_name
  
}

data "azurerm_storage_container" "default" {
  depends_on          = [module.infra]  # refresh cluster state before reading
  name                = local.storage_container_name
  storage_account_name = local.storage_account_name
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

module "infra" {
  source                                  = "./infra"
  metaflow_resource_group_name            = local.metaflow_resource_group_name
  metaflow_database_server_admin_login    = local.metaflow_database_server_admin_login
  metaflow_database_server_admin_password = local.metaflow_db_password
  location                                = local.location
  storage_container_name                  = local.storage_container_name
  storage_account_name                    = local.storage_account_name
  kubernetes_cluster_name                 = local.kubernetes_cluster_name
  database_server_name                    = local.database_server_name
  service_principal_name                  = local.storage_service_principal_name
  virtual_network_name                    = local.virtual_network_name
  db_subnet_name                          = local.db_subnet_name
  k8s_subnet_name                         = local.k8s_subnet_name
  deploy_airflow                          = var.deploy_airflow
}

module "services" {
  depends_on = [module.infra]
  source     = "./services"

  metadata_service_image                       = local.metadata_service_image
  metaflow_ui_static_service_image             = local.metaflow_ui_static_service_image
  metaflow_ui_backend_service_image            = local.metaflow_ui_backend_service_image
  metaflow_datastore_sysroot_azure             = local.metaflow_datastore_sysroot_azure
  metaflow_storage_account_name                = data.azurerm_storage_account.default.name
  metaflow_azure_storage_blob_service_endpoint = data.azurerm_storage_account.default.primary_blob_endpoint
  metaflow_db_port                             = local.metaflow_db_port
  metaflow_db_name                             = local.metaflow_db_name
  kubeconfig                                   = data.azurerm_kubernetes_cluster.default.kube_config_raw
  metaflow_db_host                             = data.azurerm_postgresql_flexible_server.default.fqdn
  metaflow_db_user                             = local.metaflow_database_server_admin_login
  metaflow_db_password                         = local.metaflow_db_password
  metaflow_kubernetes_secret_name              = local.metaflow_kubernetes_secret_name
  azure_storage_credentials                    = {
    AZURE_CLIENT_ID     = module.infra.service_principal_client_id
    AZURE_TENANT_ID     = module.infra.service_principal_tenant_id
    AZURE_CLIENT_SECRET = module.infra.service_principal_client_secret
  }
  
  deploy_airflow                          = var.deploy_airflow
  deploy_argo                             = var.deploy_argo
  
  airflow_version =  local.airflow_version
  airflow_frenet_secret =  local.airflow_frenet_secret
}
