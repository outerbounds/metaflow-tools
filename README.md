> **Note:** This repository is **not** for [Outerbounds](https://outerbounds.com) deployments. It is focused on **open-source (OSS) Metaflow** usage and tooling.
> 
[![](https://img.shields.io/badge/slack-@outerbounds-purple.svg?logo=slack )](http://slack.outerbounds.co/) 
 
# ⚒️ Metaflow Admin Tools

This repository contains various configuration files, tools and utilities for operating OSS [Metaflow](https://github.com/Netflix/metaflow) in production. See [Metaflow documentation](https://docs.metaflow.org) for more information about Metaflow architecture. Top level folders are structured as follows:

## Metaflow on AWS (/aws)
### Metaflow Cloudformation template
If you're not already using Terraform, this is the easiest way to get started on AWS. You can find the template under [aws/cloudformation](./aws/cloudformation) in this repository.
This stack uses AWS Batch for compute and AWS Step Functions for orchestration.

### Sample Terraform templates for AWS
Another deployment option is using Terraform. An end-to-end example can be found under [aws/terraform](./aws/terraform) in this repository. The example leverages the official Terraform module [outerbounds/terraform-aws-metaflow](https://registry.terraform.io/modules/outerbounds/metaflow/aws/latest) as a building block.
This stack uses AWS Batch for compute and AWS Step Functions for orchestration.

## Metaflow on Azure (/azure)
### Sample Terraform templates for Azure
This is the quickest way to spin up a fully functional Metaflow stack on Azure. See details under [azure/terraform](./azure/terraform) in this repository.
This stack uses Kubernetes (AKS) for compute and Argo Workflows for orchestration.

## Metaflow on Nebius AI Cloud (/nebius)
### Sample Terraform templates for Nebius AI Cloud
This is another quickest way to spin up a fully functional Metaflow stack on Nebius. See details under [nebius/terraform](./nebius/terraform) in this repository.
This stack uses Kubernetes (Managed Service for Kubernetes in Nebius AI Cloud) for compute and Argo Workflows for orchestration.

## Metaflow services on Kubernetes (/k8s)
### Helm Charts (alpha)
We provide Helm charts to deploy Metaflow Metadata service and UI in a K8S cluster. This way you can use Metaflow without any AWS-specific dependencies on AWS except for having a S3-compatible object storage engine available. You can find them under [charts/metaflow](./charts/metaflow) in this repository.

## Cloud agnostic resources (/common)
### Sample Metaflow flow definitions
Some Metaflow flows that could be used to test drive a Metaflow stack. Some of these flows
are used to drive end-to-end CI coverage internally at Outerbounds.  They live under [common/sample_flows](./common/sample_flows)

## Utility scripts (/scripts)
Scripts that make life easier either deploying or using your new Metaflow stacks.

# Questions?
Talk to us on [Slack](http://http://slack.outerbounds.co/).
