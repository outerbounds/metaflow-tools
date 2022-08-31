resource "google_storage_bucket" metaflow_storage_bucket {
  provider = google-beta
  name          = var.storage_bucket_name
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}
