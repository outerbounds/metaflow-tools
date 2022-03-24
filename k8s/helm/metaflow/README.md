# Helm Chart for Metaflow services

This chart deploys Metaflow Services in a Kubernetes cluster. Specifically, it includes:

* a sub-chart for Metaflow Metadata service
* a sub-chart for Metaflow UI, front end and back end
* PostgreSQL to store Metadata

PostgreSQL subchart is included to make it easier to deploy Metaflow for evaluation or development purposes. In production, we recommend to use a managed PostgreSQL offering such as AWS RDS and disable PostgreSQL sub-chart by setting `postgresql.enabled` to `false`.

