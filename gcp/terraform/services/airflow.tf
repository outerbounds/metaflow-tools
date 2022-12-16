resource "kubernetes_namespace" "airflow" {
  count = var.deploy_airflow ? 1 : 0
  metadata {
    name = "airflow"
  }
}

locals {
  airflow_values = {
    "executor" = "LocalExecutor"
    "defaultAirflowTag" = var.airflow_version
    "airflowVersion" = var.airflow_version
    "webserverSecretKey" = var.airflow_frenet_secret
  }
}


resource "helm_release" "airflow" {
  count = var.deploy_airflow ? 1 : 0
  name  = "airflow-deployment"

  repository = "https://airflow.apache.org"
  chart      = "airflow"

  namespace = kubernetes_namespace.airflow[0].metadata[0].name

  timeout = 1200

  wait = false # Why set `wait=false` 
  #: Read this (https://github.com/hashicorp/terraform-provider-helm/issues/683#issuecomment-830872443)
  # Short summary : If this is not set then airflow doesn't end up running migrations on the database. That makes the scheduler and other containers to keep waiting for migrations. 

  values = [
    yamlencode(local.airflow_values)
  ]
}
# annotation is added to the scheduler's pod so that the pod's service account can 
# talk to Google cloud storage. 
resource "kubernetes_annotations" "airflow_service_account_annotation" {
  count = var.deploy_airflow ? 1 : 0
  depends_on = [helm_release.airflow]
  api_version = "v1"
  kind        = "ServiceAccount"
  metadata {
    name      = "airflow-deployment-scheduler"
    namespace = kubernetes_namespace.airflow[0].metadata[0].name
  }
  annotations = {
    "iam.gke.io/gcp-service-account" = "${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
  }
}