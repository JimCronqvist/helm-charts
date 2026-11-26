{{/*
Expand the name of the chart.
*/}}
{{- define "tailscale-kubernetes-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 53 chars because some Kubernetes name fields are limited to this (by the Helm ReleaseName spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tailscale-kubernetes-api.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 53 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if or (contains $name .Release.Name) (eq "tailscale-kubernetes-api" $name) }}
{{- .Release.Name | trunc 53 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 53 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tailscale-kubernetes-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tailscale-kubernetes-api.labels" -}}
helm.sh/chart: {{ include "tailscale-kubernetes-api.chart" . }}
{{ include "tailscale-kubernetes-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tailscale-kubernetes-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tailscale-kubernetes-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Tailscale Operator Service annotations
*/}}
{{- define "helpers.tailscale-annotations" -}}
{{- if and .Values.tailscale .Values.tailscale.enabled }}
{{- $defaultHostname := printf "kubernetes-api-%s" (.Values.clusterName | default "") | trimSuffix "-" }}
tailscale.com/expose: "true"
tailscale.com/hostname: "{{ printf "%s-" .Values.tailscale.prefix | trimPrefix "-" }}{{ .Values.tailscale.hostname | default $defaultHostname }}"
tailscale.com/tags: {{ .Values.tailscale.tags | default "tag:k8s" | quote }}
{{- end }}
{{- end }}
