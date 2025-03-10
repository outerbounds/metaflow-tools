# There is an airflow related S3 storage container required as a part of the deployment when deploying airflow

# This is done because airflow doesn't allow any way of configuring the container name in the S3 store and assumes `airflow-logs` as the container name where airflow writes its logs (Airflow 2.3.3 with it's associated helm chart). 

# Hence `airflow_container` is not declared from top level and we set it in the locals here. 
locals {
    airflow_container = "airflow-logs"
}

resource "nebius_storage_v1_bucket" "airflow_logs_container" {
  name                  = local.airflow_container
  parent_id             = var.iam_project_id
  count = var.deploy_airflow ? 1 : 0
}