# A minimal viable Metaflow-on-Nebius stack

## What does it do?

It provisions all necessary Nebius resources. Main resources are:

* Nebius S3
* Nebius Mk8s

It will also deploy Metaflow services onto the Mk8s cluster above.

## Prerequisites

* Install [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).
* Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
* Install [nebius](https://docs.nebius.com/cli/quickstart/) CLI and setup it.

## Usage

The templates are organized into two modules, `infra` and `services`.

Before you do anything, create a TF vars file `FILE.tfvars` (`FILE` could be something else), with this content.

```text
tenant_id = "" # you can get from your console
project_id = "" # you can get from your console
```

This is used to help generate unique resource names for:

* MPG server name
* S3 storage account name

Note: these resources must be globally unique across all of Nebius.

Next run to obtain Iam Nebius token

```bash
. ./environment.sh
```

Note: these resources must be globally unique across all of Nebius.

Next run to obtain Iam Nebius token

```bash
. ./environment.sh
```

Next, apply the `infra` module (creates Nebius cloud resources only).

```bash
terraform apply -target="module.infra" -var-file=FILE.tfvars
```

Next, add Service Account to edit group and add values to `FILE.tfvars`. You can get values from console from SA page

```txt
aws_access_key_id = ""
aws_secret_access_key=""
```


### Airflow

NOT SUPPORTED. NEED PVC

## (Advanced) Terraform state management

Terraform manages the state of Nebius resources in [tfstate](https://www.terraform.io/language/state) files locally by default.

If you plan to maintain the minimal stack for any significant period of time, it is highly
recommended that these state files be stored in cloud storage (e.g. Nebius Storage) instead.

Some reasons include:

* More than one person needs to administer the stack (using terraform). Everyone should work off
  a single copy of tfstate.
* You wish to mitigate the risk of data-loss on your local disk.

For more details, see [Terraform docs](https://www.terraform.io/language/settings/backends/configuration).