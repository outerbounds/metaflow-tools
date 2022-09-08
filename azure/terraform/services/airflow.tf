resource "kubernetes_namespace" "airflow" {
  count = var.deploy_airflow ? 1 : 0
  metadata {
    name = "airflow"
  }
}

resource "helm_release" "airflow" {
  count = var.deploy_airflow ? 1 : 0
  name       = "airflow-deployment"

  repository = "https://airflow.apache.org"
  chart      = "airflow"
  
  namespace = "airflow"

  timeout = 1200

  wait = false # Why set `wait=false` 
              #: Read this (https://github.com/hashicorp/terraform-provider-helm/issues/683#issuecomment-830872443)
              # Short summary : If this is not set then airflow doesn't end up running migrations on the database. That makes the scheduler and other containers to keep waiting for migrations. 

  values = [
    templatefile("${path.module}/airflow/helm-values.yml", {
      airflow_version = var.airflow_version
      airflow_frenet_secret = var.airflow_frenet_secret
      azure_credentials_secret = var.metaflow_kubernetes_secret_name
      azure_account_name = var.metaflow_storage_account_name 
    })
  ]
}