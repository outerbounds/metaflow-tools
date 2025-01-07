resource "kubernetes_deployment" "metaflow-ui-static-service" {
  wait_for_rollout = false
  metadata {
    name = "metaflow-ui-static-service"
    namespace= "default"
  }
  spec {
    selector {
      match_labels = {
        app = "metaflow-ui-static-service"
      }
    }
    template {
      metadata {
        labels = {
          app  = "metaflow-ui-static-service"
        }
      }
      spec {
        container {
          image = var.metaflow_ui_static_service_image
          name  = "metaflow-ui-static-service"
          port {
            container_port = 3000
            name =  "http"
            protocol = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
          }
          resources {
            requests = {
              memory = "1000M"
              cpu    = "500m"
            }
          }
          # How to reach UI backend from **outside** cluster
          # It is the *UI backend* (suboptimal naming)
          env {
            name = "METAFLOW_SERVICE"
            value=  "http://localhost:8083/api"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "metaflow-ui-static-service" {
  metadata {
    name = "metaflow-ui-static-service"
    namespace= "default"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "metadata-ui-static-service"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol = "TCP"
    }
  }
}