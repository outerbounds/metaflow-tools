resource "azurerm_kubernetes_cluster" "metaflow_kubernetes" {
  name                = var.kubernetes_cluster_name
  location            = azurerm_resource_group.metaflow_resource_group.location
  resource_group_name = azurerm_resource_group.metaflow_resource_group.name

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
    enable_auto_scaling = true
    min_count  = 1
    max_count  = 10
    vnet_subnet_id = azurerm_subnet.metaflow_kubernetes_subnet.id
  }
  lifecycle {
    ignore_changes = [default_node_pool.0.node_count]
  }

  dns_prefix = var.kubernetes_cluster_name

  identity {
    type = "SystemAssigned"
  }

  # We think "stable" upgrades the cluster control plane AND updates node images
  # https://stackoverflow.com/questions/72289012/why-update-aks-cluster-also-update-the-node-image
  automatic_channel_upgrade = "stable"

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "metaflow_kubernetes_compute_node_pool" {
  name                  = "taskworkers"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.metaflow_kubernetes.id
  vm_size               = "Standard_D4_v5"
  node_count            = 1
  enable_auto_scaling = true
  vnet_subnet_id = azurerm_subnet.metaflow_kubernetes_subnet.id
  min_count = 1
  max_count = 50

  lifecycle {
    ignore_changes = [node_count]
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.metaflow_kubernetes.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.metaflow_kubernetes.kube_config_raw

  sensitive = true
}