# TODO rename to "_for_default"
resource "kubernetes_service_account" "metaflow_service_account" {
  metadata {
    name      = var.metaflow_workload_identity_ksa_name
    namespace = "default"
    annotations = {
      "iam.gke.io/gcp-service-account" = "${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
    }
  }
}

resource "google_service_account_iam_binding" "metaflow-service-account-iam" {
  service_account_id = var.metaflow_workload_identity_gsa_id
  role               = "roles/iam.workloadIdentityUser"

  members = flatten([
    "serviceAccount:${var.project}.svc.id.goog[${kubernetes_service_account.metaflow_service_account.id}]",
    var.deploy_airflow ? ["serviceAccount:${var.project}.svc.id.goog[airflow/airflow-deployment-scheduler]"] : [],
    var.deploy_argo ? ["serviceAccount:${var.project}.svc.id.goog[argo/argo]"] : [],
  ])
}