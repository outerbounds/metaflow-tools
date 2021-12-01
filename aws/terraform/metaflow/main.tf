provider "aws" {
  region = var.aws_region
}

module "common_vars" {
  source = "../modules/common"

  app = var.app
  env = var.env
}

module "metaflow" {
  source = "github.com/outerbounds/terraform-aws-metaflow"

  resource_prefix = local.resource_prefix
  resource_suffix = local.resource_suffix

  access_list_cidr_blocks                = var.access_list_cidr_blocks
  api_basic_auth                         = var.api_basic_auth
  batch_type                             = var.batch_type
  compute_environment_desired_vcpus      = var.compute_environment_desired_vcpus
  compute_environment_instance_types     = var.compute_environment_instance_types
  compute_environment_max_vcpus          = var.compute_environment_max_vcpus
  compute_environment_min_vcpus          = var.compute_environment_min_vcpus
  enable_custom_batch_container_registry = var.enable_custom_batch_container_registry
  enable_step_functions                  = var.enable_step_functions
  iam_partition                          = var.iam_partition
  subnet1_id                             = data.terraform_remote_state.infra.outputs.subnet1_id
  subnet2_id                             = data.terraform_remote_state.infra.outputs.subnet2_id
  vpc_cidr_block                         = data.terraform_remote_state.infra.outputs.vpc_cidr_block
  vpc_id                                 = data.terraform_remote_state.infra.outputs.vpc_id

  tags = module.common_vars.tags
}

resource "local_file" "metaflow_config" {
  content  = module.metaflow.metaflow_profile_json
  filename = "${path.module}/${local.metaflow_config_filename}"
}
