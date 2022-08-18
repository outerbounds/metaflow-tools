resource "kubernetes_secret" "argo-jobs-azure-credentials" {
  metadata {
    name = "metaflow-azure-storage-credentials"
    namespace = "argo"
  }
  type = "Opaque"
  data = var.azure_storage_credentials
}

# This is used by --with=kubernetes runs, and Metaflow UI backend service.
resource "kubernetes_secret" "default-jobs-azure-credentials" {
  metadata {
    name = "metaflow-azure-storage-credentials"
    namespace = "default"
  }
  type = "Opaque"
  data = var.azure_storage_credentials
}