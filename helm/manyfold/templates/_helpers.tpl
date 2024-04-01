{{/*
Expand the name of the chart.
*/}}
{{- define "manyfold.name" -}}
{{- default .Chart.Name .Values.manyfold.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "manyfold.fullname" -}}
{{- if .Values.manyfold.fullnameOverride }}
{{- .Values.manyfold.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.manyfold.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "manyfold.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "manyfold.labels" -}}
helm.sh/chart: {{ include "manyfold.chart" . }}
{{ include "manyfold.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "manyfold.selectorLabels" -}}
app.kubernetes.io/name: {{ include "manyfold.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "manyfold.serviceAccountName" -}}
{{- if .Values.manyfold.serviceAccount.create }}
{{- default (include "manyfold.fullname" .) .Values.manyfold.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.manyfold.serviceAccount.name }}
{{- end }}
{{- end }}
