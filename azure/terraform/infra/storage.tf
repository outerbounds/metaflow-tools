resource "azurerm_storage_account" "metaflow_storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.metaflow_resource_group.name
  location                 = azurerm_resource_group.metaflow_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "metaflow"
  }
}

resource "azurerm_storage_container" "metaflow_storage_container" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.metaflow_storage_account.name
  container_access_type = "private"
}

