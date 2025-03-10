resource "nebius_msp_postgresql_v1alpha1_cluster" "metaflow_database_server" {
  parent_id = var.iam_project_id
  name = var.database_server_name
  bootstrap = {
    db_name = "metaflow"
    user_name = var.metaflow_database_server_admin_login
    user_password = var.metaflow_database_server_admin_password
  }
  config = {
    template = {
      disk = {
        size_gibibytes = 32
        type = "nebius-network-ssd"
      }
      hosts = {
        count = 1
      }
      resources = {
        platform = "cpu-e2"
        preset = "2vcpu-8gb"
      }
    }
    version = 16
  }
  network_id = var.nebius_network_id
}