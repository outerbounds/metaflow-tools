{{/*
Expand the name of the chart.
*/}}
{{- define "metaflow-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "metaflow-ui.name-static" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}-static
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metaflow-ui.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metaflow-ui.fullname-static" -}}
{{ include "metaflow-ui.fullname" . }}-static
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metaflow-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metaflow-ui.labels" -}}
helm.sh/chart: {{ include "metaflow-ui.chart" . }}
{{ include "metaflow-ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metaflow-ui.labelsStatic" -}}
helm.sh/chart: {{ include "metaflow-ui.chart" . }}
{{ include "metaflow-ui.selectorLabelsStatic" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metaflow-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metaflow-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metaflow-ui.selectorLabelsStatic" -}}
app.kubernetes.io/name: {{ include "metaflow-ui.name-static" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metaflow-ui.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metaflow-ui.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "metaflow-ui.metadatadbEnvVars" -}}
- name: MF_METADATA_DB_NAME
  value: {{ .Values.metadatadb.name | quote }}
- name: MF_METADATA_DB_PORT
  value: {{ .Values.metadatadb.port | quote }}
- name: MF_METADATA_DB_PSWD
  value: {{ .Values.metadatadb.password | quote }}
- name: MF_METADATA_DB_USER
  value: {{ .Values.metadatadb.user | quote }}
{{- if .Values.metadatadb.host }}
- name: MF_METADATA_DB_HOST
  value: {{ .Values.metadatadb.host | quote }}
{{- else }}
- name: MF_METADATA_DB_HOST
  value: {{ .Release.Name }}-postgresql
{{- end -}}
{{- if .Values.metadatadb.schema }}
- name: DB_SCHEMA_NAME
  value: {{ .Values.metadatadb.schema | quote }}
{{- end }}
{{- end -}}
