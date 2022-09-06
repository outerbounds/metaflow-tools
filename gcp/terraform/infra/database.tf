resource "google_sql_database_instance" "metaflow_database_server" {
  provider = google-beta

  name             = var.database_server_name
  region           = var.region
  database_version = "POSTGRES_14"

  # convenience tradeoff here - this allows easy cleanup of the whole stack
  deletion_protection = false

  depends_on = [google_service_networking_connection.metaflow_database_private_vpc_connection]

  settings {
    tier = "db-custom-1-3840"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.metaflow_compute_network.id
    }
    backup_configuration {
      enabled = true
    }
  }
}

resource "google_sql_user" "metaflow_db_user" {
  provider = google-beta
  name     = "metaflow"
  instance = google_sql_database_instance.metaflow_database_server.id
  password = "metaflow"
  deletion_policy = "ABANDON"
}

resource "google_sql_database" "metaflow_database" {
  provider = google-beta
  name     = "metaflow"
  instance = google_sql_database_instance.metaflow_database_server.id
}

