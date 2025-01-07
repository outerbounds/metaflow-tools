resource "nebius_storage_v1_bucket" "metaflow_storage_container" {
  name                  = var.storage_container_name
  parent_id             = var.project_id
}

resource "nebius_iam_v1_service_account" "metaflow_storage_account" {
  parent_id             = var.project_id
  name                  = var.storage_account_name
}

# This need admin permisiions 
# 
# data "nebius_iam_v1_group" "editor_group" {
#   name      = "editors"
#   parent_id = var.tenant_id
# }

# resource "nebius_iam_v1_group_membership" "metaflow_storage_account_editor" {
#   parent_id = data.nebius_iam_v1_group.editor_group.id
#   member_id = nebius_iam_v1_service_account.metaflow_storage_account.id
# }
