# There is an airflow related blob-storage container required as a part of the deployment when deploying airflow

# This is done because airflow doesn't allow any way of configuring the container name in the azure blob store and assumes `airflow-logs` as the container name where airflow writes its logs (Airflow 2.3.3 with it's associated helm chart). 

# Hence `airflow_container` is not declared from top level and we set it in the locals here. 
locals {
    airflow_container = "airflow-logs"
}

resource "azurerm_storage_container" "airflow_logs_container" {
  name                  = local.airflow_container
  storage_account_name  = azurerm_storage_account.metaflow_storage_account.name
  container_access_type = "private"
  count = var.deploy_airflow ? 1 : 0
}

resource "azurerm_role_assignment" "airflow_storage_role_permissions" {
  scope                = azurerm_storage_container.airflow_logs_container[0].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.service_principal.id
  count = var.deploy_airflow ? 1 : 0
}
