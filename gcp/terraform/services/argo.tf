resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argo"
  }
}

resource "kubernetes_namespace" "argo-events" {
  count = var.deploy_argo_events ? 1 : 0
  metadata {
    name = "argo-events"
  }
}

locals {
  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
  _argo_cmd  = "kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml"
  # we need to annotate the "argo" kubernetes service account for workload identity integration
  _argo_annotate_cmd        = "kubectl annotate -n argo serviceaccount argo  iam.gke.io/gcp-service-account=${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
  _argo_events_cmd          = "kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-events/v1.7.3/manifests/install.yaml"
  _service_accts_cmd        = "kubectl apply -n argo -f ${path.module}/argo_events/service_accounts.yaml"
  _event_bus_cmd            = "kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-events/v1.7.3/examples/eventbus/native.yaml"
  _webhook_source_cmd       = "kubectl apply -n argo -f ${path.module}/argo_events/webhook_source.yaml"
  _argo_events_annotate_cmd = "kubectl annotate -n argo serviceaccount operate-workflow-sa  iam.gke.io/gcp-service-account=${var.metaflow_workload_identity_gsa_name}@${var.project}.iam.gserviceaccount.com"
}

# Yes local-exec is unfortunate.
# As of 7/22/2022, this did not work:
# https://registry.terraform.io/providers/gavinbunney/kubectl/1.14
# The main challenge is that the Argo yaml contains multiple k8s resources, and terraform does not accept that natively.
resource "null_resource" "argo-quick-start-installation" {
  triggers = {
    cmd = local._argo_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._argo_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._argo_cmd}"
  }
}

resource "null_resource" "argo-annotate-service-account" {
  depends_on = [null_resource.argo-quick-start-installation]
  triggers = {
    cmd = local._argo_annotate_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._argo_annotate_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._argo_annotate_cmd}"
  }
}

resource "null_resource" "argo-events-quick-start" {
  count      = var.deploy_argo_events ? 1 : 0
  depends_on = [null_resource.argo-quick-start-installation]
  triggers = {
    cmd = local._argo_events_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._argo_events_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._argo_events_cmd}"
  }
}

resource "null_resource" "argo-events-service-account" {
  depends_on = [null_resource.argo-events-quick-start]
  count      = var.deploy_argo_events ? 1 : 0
  triggers = {
    cmd = local._service_accts_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._service_accts_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._service_accts_cmd}"
  }
}

resource "null_resource" "argo-events-event-bus" {
  depends_on = [null_resource.argo-events-quick-start]
  count      = var.deploy_argo_events ? 1 : 0
  triggers = {
    cmd = local._event_bus_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._event_bus_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._event_bus_cmd}"
  }
}

resource "null_resource" "argo-events-webhook-source" {
  depends_on = [null_resource.argo-events-quick-start]
  count      = var.deploy_argo_events ? 1 : 0
  triggers = {
    cmd = local._webhook_source_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._webhook_source_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._webhook_source_cmd}"
  }
}

resource "null_resource" "argo-events-annotate-service-account" {
  depends_on = [null_resource.argo-events-service-account]
  triggers = {
    cmd = local._argo_events_annotate_cmd
  }
  provisioner "local-exec" {
    interpreter = local.is_windows ? ["PowerShell"] : null
    command     = local.is_windows ? "$env:KUBECONFIG='${var.kubeconfig_path}'; ${local._argo_events_annotate_cmd}" : "KUBECONFIG=${var.kubeconfig_path} ${local._argo_events_annotate_cmd}"
  }
}
