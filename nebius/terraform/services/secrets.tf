resource "kubernetes_secret" "argo-jobs-nebius-credentials" {
  metadata {
    name = var.metaflow_kubernetes_secret_name
    namespace = "argo"
  }
  type = "Opaque"
  data = var.nebius_storage_credentials
  count = var.deploy_argo ? 1 : 0
}

# This is used by --with=kubernetes runs, and Metaflow UI backend service.
resource "kubernetes_secret" "default-jobs-nebius-credentials" {
  metadata {
    name = var.metaflow_kubernetes_secret_name
    namespace = "default"
  }
  type = "Opaque"
  data = var.nebius_storage_credentials
}

resource "kubernetes_secret" "airflow-jobs-nebius-credentials" {
  metadata {
    name = var.metaflow_kubernetes_secret_name
    namespace = "airflow"
  }
  type = "Opaque"
  data = var.nebius_storage_credentials
  count = var.deploy_airflow ? 1 : 0
}