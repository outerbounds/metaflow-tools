output "metaflow_workload_identity_gsa_id" {
  value = google_service_account.metaflow_kubernetes_workload_identity_service_account.id
}
