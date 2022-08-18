# One virtual network, two subnets
# - one subnet for database
# - one subnet for kubernetes
# Kubernetes shares a virtual network with the database so that workloads there can access the DB
resource "azurerm_virtual_network" "metaflow_virtual_network" {
  name                = var.virtual_network_name
  location            = azurerm_resource_group.metaflow_resource_group.location
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
  address_space       = ["172.16.0.0/24", "172.17.0.0/16"]
}

resource "azurerm_subnet" "metaflow_database_subnet" {
  name                 = var.db_subnet_name
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
  virtual_network_name = azurerm_virtual_network.metaflow_virtual_network.name
  address_prefixes     = ["172.16.0.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "metaflow_kubernetes_subnet" {
  name                 = var.k8s_subnet_name
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name
  virtual_network_name = azurerm_virtual_network.metaflow_virtual_network.name
  # 65k addresses is a lot... but not a lot. This will be used by AKS workloads (1 IP per pod)
  address_prefixes     = ["172.17.0.0/16"]
}