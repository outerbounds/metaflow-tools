resource "kubernetes_namespace" "argo" {
  count = var.deploy_argo ? 1 : 0
  metadata {
    name = "argo"
  }
}

locals {
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  _apply_cmd = "kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml"
  # we need to annotate the "argo" kubernetes service account for workload identity integration
  _annotate_cmd = "kubectl annotate -n argo serviceaccount argo  iam.gke.io/gcp-service-account=${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
}

# Yes local-exec is unfortunate.
# As of 7/22/2022, this did not work:
# https://registry.terraform.io/providers/gavinbunney/kubectl/1.14
# The main challenge is that the Argo yaml contains multiple k8s resources, and terraform does not accept that natively.
resource "null_resource" "argo-quick-start-installation" {
  count = var.deploy_argo ? 1 : 0
  triggers = {
    cmd = local._apply_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._apply_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._apply_cmd}"
  }
}

resource "null_resource" "argo-annotate-service-account" {
  count      = var.deploy_argo ? 1 : 0
  depends_on = [null_resource.argo-quick-start-installation]
  triggers = {
    cmd = local._annotate_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._annotate_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._annotate_cmd}"
  }
}
