## Helm Chart for Metaflow UI

This helm chart deploys the static and backend components of the metaflow UI. It assumes that these deployments will mostly share similar configurations like `imagePullSecrets`, `tolerations`, and `affinity`. However, you can also configure the static and backend components separately via the `uiStatic` and `uiBackend` blocks respectively. Plus the helm chart also includes a way to configure the ingress resources that can optionally be deployed to server the metaflow UI.
