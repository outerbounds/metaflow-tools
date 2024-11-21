output "END_USER_SETUP_INSTRUCTIONS" {
  depends_on = [module.services]
  value      = <<EOT
V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V=V
Setup instructions for END USERS (e.g. someone running Flows vs the new stack):
-------------------------------------------------------------------------------
There are three steps:
1. Ensuring GCP access
2. Configure Metaflow
3. Run port forwards
4. Install necessary GCP Python SDK libraries

STEP 1: Ensure you have sufficient access to these GCP resources on your local workstation:

- Google Kubernetes Engine ("Kubernetes Engine Developer role")
- Google Cloud Storage ("Storage Object Admin" on bucket ${local.storage_bucket_name})

Option 1: Login with gcloud CLI

Login as a sufficiently capabable user: $ gcloud auth application-default login.

Option 2: Use service account key

Ask for the pregenerated service account key (${local.service_account_key_file}) from the administrator (the person who stood up the Metaflow stack).
Save the key file locally to your home directory. It should be made to be accessible only by you (chmod 700 <FILE>)

STEP 2: Configure your local Kubernetes context to point to the the right Kubernetes cluster:

$ gcloud container clusters get-credentials ${local.kubernetes_cluster_name} --region=${local.zone}

STEP 3: Configure Metaflow:

Copy config.json to ~/.metaflowconfig/config.json:

$ cp config.json ~/.metaflowconfig/config.json

Edit the file based on your scenario:

[For Argo only] METAFLOW_KUBERNETES_NAMESPACE=argo
[For Argo only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=argo
[For Airflow only] METAFLOW_KUBERNETES_NAMESPACE=airflow
[For Airflow only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=airflow-deployment-scheduler
[For non-Argo only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=${local.metaflow_workload_identity_ksa_name}

STEP 4: Setup port-forwards to services running on Kubernetes:

option 1 - run kubectl's manually:
$ kubectl port-forward deployment/metadata-service 8080:8080
$ kubectl port-forward deployment/metaflow-ui-backend-service 8083:8083
$ kubectl port-forward deployment/metadata-service 3000:3000
$ kubectl port-forward -n argo deployment/argo-server 2746:2746
$ kubectl port-forward -n argo service/argo-events-webhook-eventsource-svc 12000:12000

option 2 - this script manages the same port-forwards for you (and prevents timeouts)

$ python forward_metaflow_ports.py [--include-argo] [--include-airflow]

STEP 5: Install GCP Python SDK
$ pip install google-cloud-storage google-auth

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
