# Metaflow Admin Tools

This repository contains various tools and utilities for operating [Metaflow](https://github.com/Netflix/metaflow) in production. See [Metaflow's documentation](https://docs.metaflow.org) for more information.

The tools included in this repo include:

# Metaflow on AWS

To deploy Metaflow on AWS, you can use one of the options below

### [Metaflow Cloudformation template](./aws/cloudformation)

If you're not already using Terraform, this is the easiest way to get started.

### [Terraform modules](./aws/terraform)

We provide a collection of configurable Terraform modules for teams that use Terraform to manage their configuration as code.

# Metaflow on K8S

### [Helm Charts](./k8s/helm/metaflow)
We provide a couple of Helm charts to deploy Metaflow Metadata service and UI in a K8S cluster.


