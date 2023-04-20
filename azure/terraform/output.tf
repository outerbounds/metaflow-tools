output "END_USER_SETUP_INSTRUCTIONS" {
  depends_on = [module.services]
  value = <<EOT
V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V
Setup instructions for END USERS (e.g. someone running Flows vs the new stack):
-------------------------------------------------------------------------------
There are three steps:
1. Ensuring Azure access
2. Configure Metaflow
3. Run port forwards
4. Install necessary Azure Python SDK libraries


STEP 1: Ensure you have sufficient access to these Azure resources on your local workstation:

- AKS cluster ("${local.kubernetes_cluster_name}") ("Azure Kubernetes Service Contributor" + "Azure Kubernetes Service Cluster User Role")
- Azure Storage ("${local.storage_container_name}" in the storage account "${local.storage_account_name}") ("Storage Blob Data Contributor")

You can use "az login" as a sufficiently capabable account. To see the credentials for the service principal
(created by terraform) that is capable, run this:

$ terraform output -raw SERVICE_PRINCIPAL_CREDENTIALS

Use the credentials with "az login"

$ az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

Configure your local Kubernetes context to point to the the right Kubernetes cluster:

$ az aks get-credentials --resource-group ${data.azurerm_kubernetes_cluster.default.resource_group_name} --name ${data.azurerm_kubernetes_cluster.default.name}

STEP 2: Configure Metaflow:

Option 1: Create JSON config directly

Copy config.json to ~/.metaflowconfig/config.json:

$ cp config.json ~/.metaflowconfig/config.json

If deployed with Airflow or Argo then remove the `METAFLOW_KUBERNETES_SERVICE_ACCOUNT` key from the json file. 
If deployed with Airflow set `METAFLOW_KUBERNETES_NAMESPACE` to "airflow". 
If deployed with Argo set `METAFLOW_KUBERNETES_NAMESPACE` to "argo". 

Option 2: Interactive configuration

Run the following, one after another.

$ metaflow configure azure
$ metaflow configure kubernetes

Use these values when prompted:

METAFLOW_DATASTORE_SYSROOT_AZURE=${local.metaflow_datastore_sysroot_azure}
METAFLOW_AZURE_STORAGE_BLOB_SERVICE_ENDPOINT=${data.azurerm_storage_account.default.primary_blob_endpoint}
METAFLOW_KUBERNETES_SECRETS=${local.metaflow_kubernetes_secret_name}
METAFLOW_SERVICE_URL=http://127.0.0.1:8080/
METAFLOW_SERVICE_INTERNAL_URL=http://metadata-service.default:8080/
[For Airflow only] METAFLOW_KUBERNETES_NAMESPACE=airflow
[For Argo only] METAFLOW_KUBERNETES_NAMESPACE=argo

Note: you can skip these:

METAFLOW_SERVICE_AUTH_KEY
METAFLOW_KUBERNETES_SERVICE_ACCOUNT
METAFLOW_KUBERNETES_CONTAINER_REGISTRY
METAFLOW_KUBERNETES_CONTAINER_IMAGE

STEP 3: Setup port-forwards to services running on Kubernetes:

option 1 - run kubectl's manually:
$ kubectl port-forward deployment/metadata-service 8080:8080
$ kubectl port-forward deployment/metaflow-ui-backend-service 8083:8083
$ kubectl port-forward deployment/metadata-ui-static-service 3000:3000
$ kubectl port-forward -n argo deployment/argo-server 2746:2746

option 2 - this script manages the same port-forwards for you (and prevents timeouts)

$ python forward_metaflow_ports.py [--include-argo] [--include-airflow]

STEP 4: Install Azure Python SDK
$ pip install azure-storage-blob azure-identity

#^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^
EOT
}

output "SERVICE_PRINCIPAL_CREDENTIALS" {
  value = <<EOT
AZURE_TENANT_ID=${module.infra.service_principal_tenant_id}
AZURE_CLIENT_ID=${module.infra.service_principal_client_id}
AZURE_CLIENT_SECRET=${module.infra.service_principal_client_secret}
EOT
  sensitive = true
}
