resource "nebius_mk8s_v1_cluster" "metaflow_kubernetes" {
  parent_id           = var.iam_project_id
  name                = var.kubernetes_cluster_name
  control_plane = {
    subnet_id = var.vpc_subnet_id
    endpoints = {
        public_endpoint = {}
    }
  }
  # TODO Switch to kube_config when it will be available
  provisioner "local-exec" {
    command = "nebius mk8s cluster get-credentials --id ${self.id} --external --force"
  }
}

resource "nebius_mk8s_v1_node_group" "nodes" {
   parent_id           = nebius_mk8s_v1_cluster.metaflow_kubernetes.id
   name                = "taskworkers"
   autoscaling = {
    min_node_count = 1
    max_node_count = 50
   }
   template = {
     resources = {
       platform = "cpu-e2"
       preset = "16vcpu-64gb"
     }
   }
 }
