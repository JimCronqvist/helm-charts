{{/*
Expand the name of the chart.
*/}}
{{- define "docker-image-pull-secret.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "docker-image-pull-secret.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "docker-image-pull-secret.labels" -}}
helm.sh/chart: {{ include "docker-image-pull-secret.chart" . }}
{{ include "docker-image-pull-secret.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "docker-image-pull-secret.selectorLabels" -}}
app.kubernetes.io/name: {{ include "docker-image-pull-secret.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
  Generate the 'dockerconfigjson' json for the secret
*/}}
{{- define "docker-image-pull-secret.dockerconfigjson" }}
  {{- print "{\"auths\":{" }}
  {{- range $index, $item := .Values.imageCredentials }}
    {{- if $index }}
      {{- print "," }}
    {{- end }}
    {{- printf "\"%s\":{\"username\":\"%s\", \"password\":\"%s\", \"auth\":\"%s\"}" $item.registry $item.username $item.accessToken (printf "%s:%s" $item.username $item.accessToken | b64enc) }}
  {{- end }}
  {{- print "}}" }}
{{- end }}
