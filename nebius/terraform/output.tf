output "END_USER_SETUP_INSTRUCTIONS" {
  depends_on = [module.services]
  value = <<EOT
V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V
Setup instructions for END USERS (e.g. someone running Flows vs the new stack):
-------------------------------------------------------------------------------
There are three steps:
1. Ensuring Nebius access
2. Configure Metaflow
3. Run port forwards


STEP 1: Ensure you have sufficient access to these Nebius resources on your local workstation:

- MK8S cluster ("${local.kubernetes_cluster_name}") ("Nebius mk8s")
- Nebius Storage ("${var.storage_container_name}" in the storage account "${local.storage_account_name}")

You can use "nebius profile create" as a sufficiently capabable account. To see the credentials for the service principal
(created by terraform) that is capable, run this:

$ terraform output -raw SERVICE_PRINCIPAL_CREDENTIALS

Export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in the environment.

$ export AWS_ACCESS_KEY_ID=""
$ export AWS_SECRET_ACCESS_KEY=""

Use the credentials with "nebius profile create"

$ nebius profile create --parent-id $NB_PROJECT_ID

Configure your local Kubernetes context to point to the the right Kubernetes cluster:

$ nebius mk8s cluster get-credentials --id ${data.nebius_mk8s_v1_cluster.default.id} --external --force

STEP 2: Configure Metaflow:

Create JSON config directly

Copy config.json to ~/.metaflowconfig/config.json:

$ cp config.json ~/.metaflowconfig/config.json

If deployed with Airflow or Argo then remove the `METAFLOW_KUBERNETES_SERVICE_ACCOUNT` key from the json file. 
If deployed with Airflow set `METAFLOW_KUBERNETES_NAMESPACE` to "airflow". 
If deployed with Argo set `METAFLOW_KUBERNETES_NAMESPACE` to "argo". 

STEP 3: Setup port-forwards to services running on Kubernetes:

option 1 - run kubectl's manually:
$ kubectl port-forward deployment/metadata-service 8080:8080
$ kubectl port-forward deployment/metaflow-ui-backend-service 8083:8083
$ kubectl port-forward deployment/metadata-ui-static-service 3000:3000
$ kubectl port-forward -n argo deployment/argo-server 2746:2746
$ kubectl port-forward -n argo service/argo-events-webhook-eventsource-svc 12000:12000

option 2 - this script manages the same port-forwards for you (and prevents timeouts)

$ python3 forward_metaflow_ports.py [--include-argo] [--include-airflow]

Now you can access Metaflow UI at http://localhost:3000/ and Argo at http://localhost:2746/.

ADVANCED TOPICS
---------------

Q: How to publish an Argo Event from outside the Kubernetes cluster?
A: Ensure `forward_metaflow_ports.py --include-argo` is running. Here is a snippet that publishes
   the event "foo" (consume this event with `@trigger(event="foo")`):
```
from metaflow.integrations import ArgoEvent

def main():
    evt = ArgoEvent('foo', url="http://localhost:12000/metaflow-event")
    evt.publish(force=True)

if __name__ == '__main__':
    main()
```

#^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^
EOT
}

output "SERVICE_PRINCIPAL_CREDENTIALS" {
  depends_on = [module.services]
  value = <<EOT
AWS_ACCESS_KEY_ID=${var.aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${var.aws_secret_access_key}
EOT
  sensitive = true
}
