terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.31.0"
    }
  }
}

provider "google-beta" {
  region = var.region
  project = var.project
}
