resource google_service_account "metaflow_kubernetes_workload_identity_service_account" {
  provider     = google-beta
  account_id   = var.metaflow_workload_identity_gsa_name
  display_name = "Service Account for Kubernetes Workload Identity (${terraform.workspace})"
}

resource "google_service_account_key" "metaflow_kubernetes_workload_identity_service_account_key" {
  service_account_id = google_service_account.metaflow_kubernetes_workload_identity_service_account.name
}

resource "local_file" metaflow_gsa_key {
  filename = var.service_account_key_file
  content  = base64decode(google_service_account_key.metaflow_kubernetes_workload_identity_service_account_key.private_key)
}

resource "google_project_iam_member" "service_account_is_cloudsql_client" {
  provider = google-beta
  project  = var.project
  role     = "roles/cloudsql.client"
  member   = "serviceAccount:${google_service_account.metaflow_kubernetes_workload_identity_service_account.email}"
  condition {
    expression  = "resource.service == \"sqladmin.googleapis.com\" && resource.name == \"projects/${var.project}/instances/${google_sql_database_instance.metaflow_database_server.name}\""
    title       = "access_db_server"
    description = "To access DB server (${google_sql_database_instance.metaflow_database_server.name})"
  }
  depends_on = [google_sql_database_instance.metaflow_database_server]
}


resource "google_project_iam_member" "service_account_is_container_developer" {
  provider   = google-beta
  project    = var.project
  role       = "roles/container.developer"
  member     = "serviceAccount:${google_service_account.metaflow_kubernetes_workload_identity_service_account.email}"
  depends_on = [google_container_cluster.metaflow_kubernetes]
}

resource "google_project_iam_member" "service_account_is_storage_object_admin" {
  provider = google-beta
  project  = var.project
  role     = "roles/storage.objectAdmin"
  member   = "serviceAccount:${google_service_account.metaflow_kubernetes_workload_identity_service_account.email}"
  condition {
    expression  = "resource.name.startsWith(\"projects/_/buckets/${google_storage_bucket.metaflow_storage_bucket.name}\")"
    title       = "access_storage_bucket"
    description = "To access storage bucket (${google_storage_bucket.metaflow_storage_bucket.name})"
  }
  depends_on = [google_storage_bucket.metaflow_storage_bucket]
}