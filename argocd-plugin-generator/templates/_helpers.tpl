{{/*
Expand the name of the chart.
*/}}
{{- define "argocd-plugin-generator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 53 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "argocd-plugin-generator.fullname" -}}
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
{{- define "argocd-plugin-generator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "argocd-plugin-generator.labels" -}}
helm.sh/chart: {{ include "argocd-plugin-generator.chart" . }}
{{ include "argocd-plugin-generator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "argocd-plugin-generator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "argocd-plugin-generator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create a helper to map environment variables, both for sensitive (secrets) and non-sensitive (env vars).
*/}}
{{- define "helpers.list-env-variables"}}
{{- $fullName := include "argocd-plugin-generator.fullname" . -}}
{{- range $key, $val := .Values.secrets }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $fullName }}
      key: {{ $key }}
{{- end }}
{{- range $key, $val := .Values.env }}
- name: {{ $key }}
  value: {{ $val | quote }}
{{- end }}
{{- end }}

{{/*
Helper to generate a random string
*/}}
{{- define "helpers.random-string" -}}
{{- randAlphaNum 40 | nospace -}}
{{- end -}}

{{/*
Checksum pod annotations
*/}}
{{- define "argocd-plugin-generator.checksumPodAnnotations" -}}
{{- $files := list "secrets.yaml" "script-configmap.yaml" "applicationset-configmap.yaml" -}}
{{- range $files }}
checksum/{{ . }}: {{ include (print $.Template.BasePath (printf "/%s" .)) $ | sha256sum }}
{{- end }}
{{- $valueKeys := list "env" "secrets" -}}
{{- range $valueKeys }}
{{- if index $.Values . }}
checksum/values.{{ . }}: {{ index $.Values . | toJson | sha256sum }}
{{- end }}
{{- end }}
{{- end }}
