resource "google_compute_backend_service" "metaflow" {
  count = var.environment == "dev" ? 1 : 0
  name  = "metaflow"
  backend {
    group = google_compute_region_network_endpoint_group.metaflow[0].id
  }
  iap {
    oauth2_client_id     = var.oauth2_client_id
    oauth2_client_secret = var.oauth2_client_secret
  }
}

resource "google_compute_url_map" "metaflow" {
  count = var.environment == "dev" ? 1 : 0
  name  = "metaflow"

  default_url_redirect {
    host_redirect = "metaflow.civiceagle.com"
    // host_redirect          = "metaflow.pluralpolicy.com"
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = true
  }

  host_rule {
    hosts        = ["metaflow.civiceagle.com", "metaflow.pluralpolicy.com"]
    path_matcher = "metaflow"
  }

  path_matcher {
    name            = "metaflow"
    default_service = google_compute_backend_service.metaflow[0].id
  }
}

resource "random_id" "metaflow-cert" {
  byte_length = 4
  prefix      = "metaflow-"

  keepers = {
    domains = join(",", ["metaflow.civiceagle.com", "metaflow.pluralpolicy.com"])
  }
}

resource "google_compute_managed_ssl_certificate" "metaflow" {
  count = var.environment == "dev" ? 1 : 0
  name  = random_id.metaflow-cert.hex

  managed {
    domains = ["metaflow.civiceagle.com", "metaflow.pluralpolicy.com"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

// configure url mappings and attach certificate
resource "google_compute_target_https_proxy" "metaflow" {
  count   = var.environment == "dev" ? 1 : 0
  name    = "metaflow"
  url_map = google_compute_url_map.metaflow[0].id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.metaflow[0].self_link,
  ]
}

resource "google_compute_region_network_endpoint_group" "metaflow" {
  count                 = var.environment == "dev" ? 1 : 0
  name                  = "metaflow"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.metaflow[0].name
  }
}

resource "google_compute_global_address" "metaflow_lb" {
  count = var.environment == "dev" ? 1 : 0
  name  = "metaflow-lb-address"
}

resource "google_compute_global_forwarding_rule" "metaflow_http_forward" {
  count      = var.environment == "dev" ? 1 : 0
  name       = "metaflow-http"
  target     = google_compute_target_http_proxy.metaflow_https_redirect[0].self_link
  ip_address = google_compute_global_address.metaflow_lb[0].address
  port_range = "80"
}

resource "google_compute_global_forwarding_rule" "metaflow_https" {
  count      = var.environment == "dev" ? 1 : 0
  name       = "metaflow"
  target     = google_compute_target_https_proxy.metaflow[0].self_link
  ip_address = google_compute_global_address.metaflow_lb[0].address
  port_range = "443"
}

resource "google_compute_url_map" "metaflow_https_redirect" {
  count = var.environment == "dev" ? 1 : 0
  name  = "metaflow-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "metaflow_https_redirect" {
  count   = var.environment == "dev" ? 1 : 0
  name    = "metaflow-http-redirect"
  url_map = google_compute_url_map.metaflow_https_redirect[0].self_link
}
