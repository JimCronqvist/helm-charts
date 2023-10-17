{{/*
Expand the name of the chart.
*/}}
{{- define "microservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 53 chars because some Kubernetes name fields are limited to this (by the Helm ReleaseNane spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "microservice.fullname" -}}
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
{{- define "microservice.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 53 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "microservice.labels" -}}
helm.sh/chart: {{ include "microservice.chart" . }}
{{ include "microservice.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "microservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "microservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "microservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "microservice.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a helper to map environment variables, both for sensitive (secrets) and non-sensitive (env vars).
*/}}
{{- define "helpers.list-env-variables"}}
{{- $fullName := include "microservice.fullname" . -}}
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
Return the Storage Class
{{- include "helpers.storage-class" (dict "persistence" .Values.path.to.the.persistence "global" .Values.global) | nindent 2 }}
*/}}
{{- define "helpers.storage-class" -}}
{{- $storageClass := .persistence.storageClass -}}
{{- if and .global .global.storageClass -}}
  {{- $storageClass = .global.storageClass -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
    {{- printf "storageClassName: \"\"" -}}
  {{- else -}}
    {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the Image Tag by using the following order:
  1. .Values.global.versions.{chartName},
  2. .Values.image.tag,
  3. .Chart.AppVersion
Useage: {{ include "helpers.image-tag" }}
*/}}
{{- define "helpers.image-tag" -}}
{{- dig (.Chart.Name) (.Values.image.tag | default .Chart.AppVersion) ((.Values.global).versions | default dict) }}
{{- end -}}

{{/*
Return the Volume Mounts
{{- with .Values.pvc }}
volumeMounts:
  {{- include "helpers.volume-mounts" . | indent 12 }}
{{- end }}
*/}}
{{- define "helpers.volume-mounts" -}}
{{- range $pvcName, $pvc := . }}
{{- range $mount := $pvc.mounts }}
- name: {{ $pvcName }}
  mountPath: {{ $mount.mountPath | quote }}
  {{- if $mount.subPath }}
  {{- if contains "$(" $mount.subPath }}
  subPathExpr: {{ $mount.subPath | quote }}
  {{- else }}
  subPath: {{ $mount.subPath | quote }}
  {{- end }}
  {{- end }}
  {{- if $mount.readOnly }}
  readOnly: {{ $mount.readOnly }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return the Volumes
{{- with .Values.pvc }}
volumes:
  {{- include "helpers.volumes" (list $ .) | indent 8 }}
{{- end }}
*/}}
{{- define "helpers.volumes" -}}
{{- $ := index . 0 }}
{{- $fullName := include (printf "%s.fullname" $.Chart.Name) $ }}
{{- with index . 1 }}
{{- range $pvcName, $pvc := . }}
- name: {{ $pvcName }}
  {{- if .hostPath }}
  hostPath:
    {{- toYaml .hostPath | nindent 12 }}
  {{- else if .nfs }}
  nfs:
    {{- toYaml .nfs | nindent 12 }}
  {{- else if .emptyDir }}
  emptyDir:
    {{- toYaml .emptyDir | nindent 12 }}
  {{- else if (dig "enabled" true $pvc) }}
  persistentVolumeClaim:
    claimName: {{ default (printf "%s-%s" $fullName $pvcName) .existingClaim }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Checksum pod annotations
*/}}
{{- define "microservice.checksumPodAnnotations" -}}
{{- $files := list "secret.yaml" "configmap-files.yaml" -}}
{{- range $files }}
checksum/{{ . }}: {{ include (print $.Template.BasePath (printf "/%s" .)) $ | sha256sum }}
{{- end }}
{{- $valueKeys := list "env" "secrets" "files" -}}
{{- range $valueKeys }}
{{- if index $.Values . }}
checksum/values.{{ . }}: {{ index $.Values . | toJson | sha256sum }}
{{- end }}
{{- end }}
{{- end }}
