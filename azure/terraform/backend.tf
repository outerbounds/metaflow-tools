terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tf-state"
    storage_account_name = "obtfstate"
    container_name       = "ob-metaflow-on-azure"
    key                  = "terraform.tfstate"
  }
}
