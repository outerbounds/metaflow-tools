data "azuread_client_config" "current" {}

# Add an application, a service principal, and a password for the service principal
# This single service principal have access to:
# - Metaflow's storage container
# - Metaflow's AKS cluster
# This is useful as this allows one set of credentials to be used on local workstations.
# E.g. an end user needs to be able to access Metaflow storage AND submit jobs to AKS (possibly)
resource "azuread_application" "service_principal_application" {
  display_name = var.service_principal_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "service_principal" {
  application_id = azuread_application.service_principal_application.application_id
  owners       = [data.azuread_client_config.current.object_id]
}

# This will be used as a AZURE_CLIENT_SECRET in Metaflow's AKS workloads
resource "azuread_service_principal_password" "service_principal_password" {
  service_principal_id = azuread_service_principal.service_principal.id
  display_name = azuread_service_principal.service_principal.display_name
}

# Allow the new service principal to access the storage container
resource "azurerm_role_assignment" "storage_role_assignment" {
  scope                = azurerm_storage_container.metaflow_storage_container.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.service_principal.id
}

# Allow the new service principal to access the AKS cluster (e.g. to submit jobs)
resource "azurerm_role_assignment" "aks_contributor_role_assignment" {
  scope                = azurerm_kubernetes_cluster.metaflow_kubernetes.id
  role_definition_name = "Azure Kubernetes Service Contributor Role"
  principal_id         = azuread_service_principal.service_principal.id
}

# Allow the new service principal to retrieve k8s credentials for the AKS cluster (e.g. az aks get-credentials)
resource "azurerm_role_assignment" "aks_user_role_assignment" {
  scope                = azurerm_kubernetes_cluster.metaflow_kubernetes.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azuread_service_principal.service_principal.id
}