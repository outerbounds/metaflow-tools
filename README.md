# Metaflow Admin Tools

This repository contains various configuration files, tools and utilities for operating [Metaflow](https://github.com/Netflix/metaflow) in production. See [Metaflow documentation](https://docs.metaflow.org) for more information about Metaflow architecture.

The tools included in this repo include:

## Metaflow Cloudformation template

If you're not already using Terraform, this is the easiest way to get started on AWS. You can find the template under [aws/cloudformation](./aws/cloudformation) in this repository.

## Terraform modules for AWS

We provide a collection of configurable Terraform modules for teams that use Terraform to manage their configuration as code. You can find the reusable modules in a separate repository [outerbounds/terraform-aws-metaflow](https://github.com/outerbounds/terraform-aws-metaflow) and [a end-to-end example](./aws/terraform) of using them in this repository.

## Helm Charts (alpha)
We provide Helm charts to deploy Metaflow Metadata service and UI in a K8S cluster. This way you can use Metaflow without any AWS-specific dependencies on AWS except for having a S3-compatible object storage engine available. You can find them under [k8s/helm/metaflow](./k8s/helm/metaflow) in this repository.


