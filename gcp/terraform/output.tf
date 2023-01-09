output "END_USER_SETUP_INSTRUCTIONS" {
  value = <<EOT
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

Configure your local Kubernetes context to point to the the right Kubernetes cluster:

$ gcloud container clusters get-credentials ${local.kubernetes_cluster_name} --region=${local.zone}

STEP 2: Configure Metaflow:

Option 1: Create JSON config directly (recommended)

Create the file "~/.metaflowconfig/config.json" with this content. If this file already exists, keep a backup of it and
move it aside first.

{
    "METAFLOW_DATASTORE_SYSROOT_GS": "${local.metaflow_datastore_sysroot_gs}",
    "METAFLOW_DEFAULT_DATASTORE": "gs",
    "METAFLOW_DEFAULT_METADATA": "service",
    "METAFLOW_KUBERNETES_NAMESPACE": "default",
    "METAFLOW_KUBERNETES_SERVICE_ACCOUNT": "${local.metaflow_workload_identity_ksa_name}",
    "METAFLOW_SERVICE_INTERNAL_URL": "http://metadata-service.default:8080/",
    "METAFLOW_SERVICE_URL": "http://127.0.0.1:8080/"
}

Option 2: Interactive configuration

Run the following, one after another.

$ metaflow configure gs
$ metaflow configure kubernetes

Use these values when prompted:

METAFLOW_DATASTORE_SYSROOT_GS=${local.metaflow_datastore_sysroot_gs}
METAFLOW_SERVICE_URL=http://127.0.0.1:8080/
METAFLOW_SERVICE_INTERNAL_URL=http://metadata-service.default:8080/
[For Argo only] METAFLOW_KUBERNETES_NAMESPACE=argo
[For Argo only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=argo
[For Airflow only] METAFLOW_KUBERNETES_NAMESPACE=airflow
[For Airflow only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=airflow-deployment-scheduler
[For non-Argo only] METAFLOW_KUBERNETES_SERVICE_ACCOUNT=${local.metaflow_workload_identity_ksa_name}

Note: you can skip these:

METAFLOW_SERVICE_AUTH_KEY
METAFLOW_KUBERNETES_CONTAINER_REGISTRY
METAFLOW_KUBERNETES_CONTAINER_IMAGE

STEP 3: Setup port-forwards to services running on Kubernetes:

option 1 - run kubectl's manually:
$ kubectl port-forward deployment/metadata-service 8080:8080
$ kubectl port-forward deployment/metaflow-ui-backend-service 8083:8083
$ kubectl port-forward deployment/metadata-service 3000:3000
$ kubectl port-forward -n argo deployment/argo-server 2746:2746

option 2 - this script manages the same port-forwards for you (and prevents timeouts)

$ python metaflow-tools/scripts/forward_metaflow_ports.py [--include-argo] [--include-airflow]

STEP 4: Install GCP Python SDK
$ pip install google-cloud-storage google-auth

#^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^=^
EOT
}