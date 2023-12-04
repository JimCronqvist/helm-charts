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
{{- if or (contains $name .Release.Name) (eq "microservice" $name) }}
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
app.kubernetes.io/version: {{ include "helpers.image-tag" . | quote }}
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
  value: {{ ternary "''" ($val | quote) (eq $val nil) }}
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
Wrap the resources cpu parts with single quotes:
Useage: {{- include "helpers.wrapResourcesWithQuotes" .Values.resources | indent 12 }}
*/}}
{{- define "helpers.wrapResourcesWithQuotes" -}}
{{- $resources := . -}}
{{- if and (not $resources.requests) (not $resources.limits) }}
{}
{{- else }}
{{- with $resources.requests }}
requests:
  {{- with .cpu }}
  cpu: {{ printf "'%s'" (. | toString) }}
  {{- end }}
  {{- with .memory }}
  memory: {{ . }}
  {{- end }}
{{- end }}
{{- with $resources.limits }}
limits:
  {{- with .cpu }}
  cpu: {{ printf "'%s'" (. | toString) }}
  {{- end }}
  {{- with .memory }}
  memory: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return the Volume Mounts
{{- with .Values.pvc }}
volumeMounts:
  {{- include "helpers.volume-mounts" (list $ . "Deployment") | indent 12 }}
{{- end }}
*/}}
{{- define "helpers.volume-mounts" -}}
{{- $ := index . 0 }}
{{- $fullName := include (printf "%s.fullname" $.Chart.Name) $ }}
{{- $kind := index . 2 }}
{{- with index . 1 }}
{{- range $pvcName, $pvc := . }}
{{- $mountToKind := dig (printf "mountTo%s" $kind) true $pvc }}
{{- if $mountToKind }}
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
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return the Volumes
{{- with .Values.pvc }}
volumes:
  {{- include "helpers.volumes" (list $ . "Deployment") | indent 8 }}
{{- end }}
*/}}
{{- define "helpers.volumes" -}}
{{- $ := index . 0 }}
{{- $fullName := include (printf "%s.fullname" $.Chart.Name) $ }}
{{- $kind := index . 2 }}
{{- with index . 1 }}
{{- range $pvcName, $pvc := . }}
{{- $mountToKind := dig (printf "mountTo%s" $kind) true $pvc }}
{{- if $mountToKind }}
- name: {{ $pvcName }}
  {{- if .hostPath }}
  hostPath:
    {{- toYaml .hostPath | nindent 4 }}
  {{- else if and .nfs (not .nfs.mountOptions) }}
  nfs:
    {{- toYaml .nfs | nindent 4 }}
  {{- else if .emptyDir }}
  emptyDir:
    {{- toYaml .emptyDir | nindent 4 }}
  {{- else if (dig "enabled" true $pvc) }}
  persistentVolumeClaim:
    claimName: {{ default (printf "%s-%s" $fullName $pvcName) .existingClaim }}
  {{- else }}
  emptyDir: {}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Return the ports for a container
{{- include "helpers.ports" (list .Values.service "primary") | indent 12 }}
*/}}
{{- define "helpers.ports" -}}
{{- $container := index . 1 }}
{{- with index . 0 }}
{{- $section := . }}
{{- if eq $container ($section.container | default "primary") }}
{{- if $section.portRange }}
{{- range until (sub $section.portRange.end $section.portRange.start | add1 | int) }}
{{- $port := add $section.portRange.start . }}
- name: {{ $section.name }}-{{ $port }}
  protocol: TCP
  containerPort: {{ $port }}
{{- end }}
{{- else }}
- name: {{ $section.name }}
  protocol: TCP
  containerPort: {{ $section.containerPort | default $section.port }}
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
