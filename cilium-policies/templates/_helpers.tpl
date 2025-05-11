{{/*
Expand the name of the chart.
*/}}
{{- define "cilium-policies.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 53 chars because some Kubernetes name fields are limited to this (by the Helm ReleaseNane spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cilium-policies.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 53 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 53 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 53 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cilium-policies.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cilium-policies.labels" -}}
helm.sh/chart: {{ include "cilium-policies.chart" . }}
{{ include "cilium-policies.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cilium-policies.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cilium-policies.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
