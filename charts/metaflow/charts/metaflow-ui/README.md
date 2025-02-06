## Helm Chart for Metaflow UI

This Helm chart facilitates the deployment of both the static and backend components of the Metaflow UI. It is designed to allow shared configurations for common settings such as `imagePullSecrets`, `tolerations`, and `affinity`. However, it also provides the flexibility to configure the static and backend components independently through the `uiStatic` and `uiBackend` sections, respectively. Additionally, the Helm chart includes options to configure ingress resources, which can be optionally deployed to serve the Metaflow UI.
