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
* `az login` as an Azure account with sufficient priviledges to administer necessary resources:
  * AKS
  * Azure storage accounts and containers
  * Virtual networks
  * AAD applications
  * ...
  * Note-1: If you are an admin of your Azure subscription already you should be good to go.
  * Note-2: It's alright to discover lacking privileges later on - you can remedy it at the point.

## Usage
The templates are organized into two modules, `infra` and `services`.

Before you do anything, uncomment and update the `org_prefix` [local variable](https://github.com/outerbounds/metaflow-on-azure/blob/21ffd571ec6e0b395234e1054c4835385a724eed/terraform/variables.tf#L8).
```
org_prefix = "yourorg"  # use something short and distinctive
```
This is used to help generate unique resource names for:
* DB server name
* Azure storage account name
Note: these resources must be globally unique across all of Azure.

Next, apply the `infra` module (creates AKS resources only).

    terraform apply -target="module.infra"

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

    terraform apply -target="module.services"

The step above will output next steps for Metaflow end users.

## (Advanced) Terraform state management
Terraform manages the state of Azure resources in [tfstate](https://www.terraform.io/language/state) files locally by default.

If you plan to maintain the minimal stack for any significant period of time, it is highly
recommended that these state files be stored in cloud storage (e.g. Azure Blob Storage) instead.

Some reasons include:
* More than one person needs to administer the stack (using terraform). Everyone should work off
  a single copy of tfstate.
* You wish to mitigate the risk of data-loss on your local disk.

For more details, see [Terraform docs](https://www.terraform.io/language/settings/backends/configuration).