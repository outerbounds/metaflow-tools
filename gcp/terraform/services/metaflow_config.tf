resource "local_file" "metaflow_config_file" {
  content = jsonencode({
    "METAFLOW_DATASTORE_SYSROOT_GS"       = var.metaflow_datastore_sysroot_gs
    "METAFLOW_DEFAULT_DATASTORE"          = "gs"
    "METAFLOW_DEFAULT_METADATA"           = "service"
    "METAFLOW_KUBERNETES_NAMESPACE"       = "default"
    "METAFLOW_KUBERNETES_SERVICE_ACCOUNT" = var.metaflow_workload_identity_ksa_name
    "METAFLOW_SERVICE_INTERNAL_URL"       = "http://metadata-service.default:8080/"
    "METAFLOW_SERVICE_URL"                = "http://127.0.0.1:8080/"
    "METAFLOW_ARGO_EVENTS_EVENT_BUS"      = "default"
    "METAFLOW_ARGO_EVENTS_EVENT_SOURCE"   = "argo-events-webhook"
    "METAFLOW_ARGO_EVENTS_EVENT"          = "metaflow-event"
    "METAFLOW_ARGO_EVENTS_WEBHOOK_URL"    = "http://argo-events-webhook-eventsource-svc.argo:12000/metaflow-event"
  })
  filename = "./config.json"
}
