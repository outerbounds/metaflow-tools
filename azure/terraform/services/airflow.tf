resource "kubernetes_namespace" "airflow" {
  count = var.deploy_airflow ? 1 : 0
  metadata {
    name = "airflow"
  }
}

resource "helm_release" "airflow" {
  name       = "airflow-deployment"

  repository = "https://airflow.apache.org"
  chart      = "airflow"
  
  namespace = "airflow"
  version    = "1.6.0"

  timeout = 1200

  wait = false # Why set `wait=false` 
              #: Read this (https://github.com/hashicorp/terraform-provider-helm/issues/683#issuecomment-830872443)

  values = [
    templatefile("${path.module}/airflow-values.yml", {
      airflow_version = var.airflow_version
      airflow_frenet_secret = var.airflow_frenet_secret
      azure_account_name = var.metaflow_storage_account_name # TODO :FIX ME !
      azure_container_name = var.metaflow_storage_container  # TODO :FIX ME !
      dags_sync_prefix = var.airflow_dags_sync_prefix
      dag_sync_frequency = var.airflow_dag_sync_frequency
      azure_credentials_secret = var.metaflow_kubernetes_secret_name # Todo : verify with jackie about this refernce not being used in secrets.tf
    })
  ]
}