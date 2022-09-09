# A minimal viable Metaflow-on-Azure stack

## What does it do?
It provisions all necessary Azure resources. Main resources are:
* Azure Blob Storage account + container
* AKS cluster
It will also deploy Metaflow services onto the AKS cluster above.

## Prerequisites

* Install [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
* Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
* Install [az](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) CLI.
* `az login` as an Azure account with sufficient privileges to administer necessary resources:
  * AKS
  * Azure storage accounts and containers
  * Virtual networks
  * AAD applications
  * ...
  * Note-1: If you are an Owner of your Azure subscription already you should be good to go.

## Usage
The templates are organized into two modules, `infra` and `services`.

Before you do anything, create a TF vars file `FILE.tfvars` (`FILE` could be something else), with this content.

    org_prefix = "yourorg"  # use something short and distinctive

This is used to help generate unique resource names for:
* DB server name
* Azure storage account name
Note: these resources must be globally unique across all of Azure.


Next, apply the `infra` module (creates Azure cloud resources only).

    terraform apply -target="module.infra" -var-file=FILE.tfvars


### Common issues:
#### PostgeSQL provisioning API errors (on Azure side)

If you do not create Azure PostgreSQL Flexible Server instances often, Azure API may be flaky initially:

    | Error: waiting for creation of the Postgresql Flexible Server "metaflow-database-server-xyz" (Resource Group "rg-db-metaflow-xyz"): 
    | Code="InternalServerError" Message="An unexpected error occured while processing the request. Tracking ID: 'xyz'"
    |
    |   with module.infra.azurerm_postgresql_flexible_server.metaflow_database_server,
    |   on infra/database.tf line 20, in resource "azurerm_postgresql_flexible_server" "metaflow_database_server":
    |   20: resource "azurerm_postgresql_flexible_server" "metaflow_database_server" {
In our experience, waiting 20 mins and trying again resolves this issue. This appears to be a one time phenomenon - future
stack spin ups do not encounter such `InternalServerError`'s.

#### Node pool provisioning
We have hardcoded some default instance type to be used for k8s nodes as well as worker pools ("taskworkers"). Depending
on real-time availability of such instances in your region or availability zone, you may consider choosing alternate instance types.

**VM Availability** issues might look something like this:

    | Error: waiting for creation of Node Pool: (Agent Pool Name "taskworkers" / Managed Cluster Name "metaflow-kubernetes-xyz" / 
    | Resource Group "rg-k8s-metaflow-xyz"): Code="ReconcileVMSSAgentPoolFailed" Message="Code=\"AllocationFailed\" Message=\"Allocation failed. 
    | We do not have sufficient capacity for the requested VM size in this region. Read more about improving likelihood of allocation success 
    | at http://aka.ms/allocation-guidance\""

**VM quotas** may also cause provisioning to fail:

    | Error: creating Node Pool: (Agent Pool Name "taskworkers" / Managed Cluster Name "metaflow-kubernetes-default" / Resource Group "rg-k8s-metaflow-default"): 
    | containerservice.AgentPoolsClient#CreateOrUpdate: Failure sending request: StatusCode=400 -- Original Error: Code="PreconditionFailed" 
    | Message="Provisioning of resource(s) for Agent Pool taskworkers failed. Error: {\n  \"code\": \"InvalidTemplateDeployment\",\n  
    | \"message\": \"The template deployment '8b1a99f1-e35e-44be-a8ac-0f82009b7149' is not valid according to the validation procedure. 
    | The tracking id is 'xyz'. See inner errors for details.\",\n  \"details\": 
    | [\n   {\n    \"code\": \"QuotaExceeded\",\n    \"message\": \"Operation could not be completed as it results in exceeding approved standardDv5Family Cores quota. 
    | Additional details - Deployment Model: Resource Manager, Location: westeurope, Current Limit: 0, Current Usage: 0, 
    | Additional Required: 4, (Minimum) New Limit Required: 4. 
    | Submit a request for Quota increase at https://<AZURE_LINK> by specifying parameters listed in the ‘Details’ section for deployment to succeed. 
    | Please read more about quota limits at https://docs.microsoft.com/en-us/azure/azure-supportability/per-vm-quota-requests\"\n   }\n  ]\n }"

Then, apply the `services` module (deploys Metaflow services to AKS)

    terraform apply -target="module.services" -var-file=FILE.tfvars

The step above will output next steps for Metaflow end users.

## Metaflow job orchestration options
The recommended way to orchestrate Metaflow workloads on Kubernetes is via [Argo Workflows](https://docs.metaflow.org/going-to-production-with-metaflow/scheduling-metaflow-flows/scheduling-with-argo-workflows). However, Airflow is also supported as an alternative.

The template also provides the `deploy_airflow` and `deploy_argo` flags as variables. These are booleans that specify if [Airflow](https://airflow.apache.org/) or [Argo Workflows](https://argoproj.github.io/argo-workflows/) will be deployed in the Kubernetes cluster along with Metaflow related services. By default `deploy_argo` is set to __true__ and `deploy_airflow` is set to __false__.
To change these, set them in your `FILE.tfvars` file (or else, via other [terraform variable](https://www.terraform.io/language/values/variables) passing mechanisms)

### Argo Workflows
Argo Workflows is installed by default on the AKS cluster as part of the `services` submodule. Setting the `deploy_argo` [variable](./variables.tf) will deploy Argo in the AKS cluster. Not additional configuration is done in the `infra` module to support `argo`.

After you have changed the value of `deploy_argo`, reapply terraform for both [infra and services](#usage).

### Airflow

**This is quickstart template only, not recommended for real production deployments**

If `deploy_airflow`  is set to true, then the `infra` module will create one more storage blob-container named `airflow-logs` and provide blob-container R/W permissions to the service principal. We create this extra blob-container because Airflow expects the blob-container where it ships logs on Azure to be named `airflow-logs`.

The `services` module will deploy Airflow via a [helm chart](https://airflow.apache.org/docs/helm-chart/stable/index.html) into the kubernetes cluster (the one deployed by the `infra` module). The Airflow installation will store all the logs in the `airflow-logs` blob-container. The terraform template deploys Airflow configured with a `LocalExecutor`. Metaflow can work with any Airflow executor. This template deploys the `LocalExecutor` for simplicity.

After you have changed the value of `deploy_airflow`, reapply terraform for both [infra and services](#usage).

#### Shipping Metaflow compiled DAGs to Airflow
Airflow expects Python files with Airflow dags present in the [dags_folder](https://airflow.apache.org/docs/apache-airflow/2.2.0/configurations-ref.html#dags-folder). By default this terraform template uses the [defaults](https://airflow.apache.org/docs/helm-chart/stable/parameters-ref.html#airflow) set in the Airflow helm chart which is `{AIRFLOW_HOME}/dags` (`/opt/airflow/dags`).

The metaflow-tools repository also ships a [airflow_dag_upload.py](../../scripts/airflow_dag_upload.py) file that can help sync Airflow dag files generated by Metaflow to the Airflow scheduler _deployed by this template_. Under the hood [airflow_dag_upload.py](../../scripts/airflow_dag_upload.py) uses the `kubectl cp` command to copy files from local to the Airflow scheduler's container. Example of how to use the file:
```
python airflow_dag_upload.py my-dag.py /opt/airflow/dags/my-dag.py
```

## (Advanced) Terraform state management
Terraform manages the state of Azure resources in [tfstate](https://www.terraform.io/language/state) files locally by default.

If you plan to maintain the minimal stack for any significant period of time, it is highly
recommended that these state files be stored in cloud storage (e.g. Azure Blob Storage) instead.

Some reasons include:
* More than one person needs to administer the stack (using terraform). Everyone should work off
  a single copy of tfstate.
* You wish to mitigate the risk of data-loss on your local disk.

For more details, see [Terraform docs](https://www.terraform.io/language/settings/backends/configuration).