terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google-beta" {
  region  = var.region
  project = var.project
}
