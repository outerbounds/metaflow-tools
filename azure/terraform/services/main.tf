terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.12.1"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
    http = {
          source = "hashicorp/http"
          version = "2.2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

# check on permissions
resource "local_file" "kubeconfig" {
  content = var.kubeconfig
  filename = "${path.root}/kubeconfig_${terraform.workspace}"
}