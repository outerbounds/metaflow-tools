module "argo_events" {
  depends_on     = [null_resource.argo-quick-start-installation]
  source         = "../../../common/terraform/argo_events"
  jobs_namespace = "argo"
}
