# Helm Chart for Metaflow Services

This Helm chart provides a comprehensive deployment solution for Metaflow Services in a Kubernetes cluster. It includes three main components:

* Metaflow Metadata Service - Manages workflow metadata and execution state
* Metaflow UI (Frontend and Backend) - Provides web-based visualization and monitoring
* PostgreSQL Database - Stores metadata for Metaflow services

While the included PostgreSQL sub-chart enables quick evaluation and development setups, for production environments we strongly recommend using a managed PostgreSQL service (like AWS RDS). To use an external database, disable the PostgreSQL sub-chart by setting `postgresql.enabled: false`.

