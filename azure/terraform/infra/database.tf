resource "azurerm_private_dns_zone" "metaflow_database_private_dns_zone" {
  name                = "metaflow.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "metaflow_database_private_dns_zone_virtual_network_link" {
  name                  = "metaflowDatabaseVnetZone.com"
  private_dns_zone_name = azurerm_private_dns_zone.metaflow_database_private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.metaflow_virtual_network.id
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
}

resource "azurerm_postgresql_flexible_server" "metaflow_database_server" {
  name                   = var.database_server_name
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
  location               = azurerm_resource_group.metaflow_resource_group.location
  version                = "12"
  delegated_subnet_id    = azurerm_subnet.metaflow_database_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.metaflow_database_private_dns_zone.id
  administrator_login    = var.metaflow_database_server_admin_login
  administrator_password = var.metaflow_database_server_admin_password
  lifecycle {
    ignore_changes = [
      zone,
      high_availability.0.standby_availability_zone,
    ]
  }

  storage_mb = 32768

  sku_name   = "B_Standard_B2s"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.metaflow_database_private_dns_zone_virtual_network_link]

}

resource "azurerm_postgresql_flexible_server_configuration" "metaflow_database_server_require_secure_transport_false" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.metaflow_database_server.id
  value     = "off"
}

resource "azurerm_postgresql_flexible_server_database" "metaflow_database_server_database" {
  name      = "metaflow"
  server_id = azurerm_postgresql_flexible_server.metaflow_database_server.id
  collation = "en_US.utf8"
  charset   = "utf8"
}