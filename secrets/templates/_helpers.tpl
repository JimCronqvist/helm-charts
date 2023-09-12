{{/*
Expand the name of the chart.
*/}}
{{- define "secrets.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "secrets.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "secrets.labels" -}}
helm.sh/chart: {{ include "secrets.chart" . }}
{{ include "secrets.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "secrets.selectorLabels" -}}
app.kubernetes.io/name: {{ include "secrets.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
