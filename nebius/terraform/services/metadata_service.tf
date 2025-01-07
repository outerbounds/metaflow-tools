resource "kubernetes_deployment" "metadata-service" {
  wait_for_rollout = false
  metadata {
    name = "metadata-service"
    namespace= "default"
  }
  spec {
    selector {
      match_labels = {
        app = "metadata-service"
      }
    }
    template {
      metadata {
        labels = {
          app  = "metadata-service"
        }
      }
      spec {
        # TODO add migration service, remove init_container
        init_container {
          image = var.metadata_service_image
          name = "db-migrations"
          command = [
            "/opt/latest/bin/python3", "/root/run_goose.py"
          ]
          resources {
            requests = {
              memory = "1000M"
              cpu = "500m"
            }
          }
          env {
            name = "MF_METADATA_DB_NAME"
            value = var.metaflow_db_name
          }
          env {
            name = "MF_METADATA_DB_PORT"
            value = var.metaflow_db_port
          }
          env {
            name = "MF_METADATA_DB_USER"
            value = var.metaflow_db_user
          }
          env {
            name = "MF_METADATA_DB_PSWD"
            value = var.metaflow_db_password
          }
          env {
            name = "MF_METADATA_DB_HOST"
            value = var.metaflow_db_host
          }
        }
        container {
          image = var.metadata_service_image
          name  = "metadata-service"
          command = ["/opt/latest/bin/python3", "-m", "services.metadata_service.server" ]
          port {
            container_port = 8080
            name =  "http"
            protocol = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/ping"
              port = "http"
            }
          }
          readiness_probe {
            http_get {
              path = "/ping"
              port = "http"
            }
          }
          resources {
            requests = {
              memory = "2000M"
              cpu = "1000m"
            }
          }
          env {
            name = "MF_METADATA_DB_NAME"
            value = var.metaflow_db_name
          }
          env {
            name = "MF_METADATA_DB_PORT"
            value = var.metaflow_db_port
          }
          env {
            name = "MF_METADATA_DB_USER"
            value = var.metaflow_db_user
          }
          env {
            name = "MF_METADATA_DB_PSWD"
            value = var.metaflow_db_password
          }
          env {
            name = "MF_METADATA_DB_HOST"
            value = var.metaflow_db_host
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "metadata-service" {
  metadata {
    name = "metadata-service"
    namespace= "default"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "metadata-service"
    }
    port {
      port        = 8080
      target_port = 8080
      protocol = "TCP"
    }
  }
}