terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.14.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.26.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "metaflow_resource_group" {
  name     = var.metaflow_resource_group_name
  location = var.location
}
