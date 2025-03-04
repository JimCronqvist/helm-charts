{{/* _pvc.tpl */}}
{{- define "microservice.render-pvc" -}}
{{- $pvcName := .pvcName -}}
{{- $pvc := .pvc -}}
{{- $global := .global -}}
{{- $labels := include "microservice.labels" (dict "context" .context ) -}}
{{- $fullName := include "microservice.fullname" .context -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $fullName }}-{{ $pvcName }}
  labels:
    {{- $labels | nindent 4 }}
  {{- if not (or $pvc.nfs (contains "efs" ($pvc.storageClass | default ""))) }}
  {{- if or $pvc.volumeType $pvc.iops $pvc.throughput }}
  annotations:
    {{- if $pvc.volumeType }}
    ebs.csi.aws.com/volumeType: {{ $pvc.volumeType | quote }}
    {{- end }}
    {{- if $pvc.iops }}
    ebs.csi.aws.com/iops: {{ $pvc.iops | quote }}
    {{- end }}
    {{- if $pvc.throughput }}
    ebs.csi.aws.com/throughput: {{ $pvc.throughput | quote }}
    {{- end }}
  {{- end }}
  {{- end }}
spec:
  accessModes:
    {{- if $pvc.accessMode }}
    - {{ $pvc.accessMode }}
    {{- else if or $pvc.nfs (contains "efs" ($pvc.storageClass | default "")) (and $pvc.csi (has $pvc.csi.driver (list "smb.csi.k8s.io" "efs.csi.aws.com" "s3.csi.aws.com"))) }}
    - ReadWriteMany
    {{- else }}
    - ReadWriteOnce
    {{- end }}
  resources:
    requests:
      {{- if or $pvc.nfs (contains "efs" ($pvc.storageClass | default "")) (and $pvc.csi (has $pvc.csi.driver (list "smb.csi.k8s.io" "efs.csi.aws.com" "s3.csi.aws.com"))) }}
      storage: 1Mi
      {{- else }}
      storage: {{ $pvc.size }}
      {{- end }}
  {{- if or $pvc.nfs $pvc.csi }}
  storageClassName: ""
  volumeName: {{ $fullName }}-{{ $pvcName }}-pv
  {{- else }}
  {{- include "helpers.storage-class" (dict "persistence" $pvc "global" $global) | nindent 2 }}
  {{- end }}
{{- if or $pvc.nfs $pvc.csi }}
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ $fullName }}-{{ $pvcName }}-pv
  labels:
    {{- $labels | nindent 4 }}
spec:
  accessModes:
    {{- if $pvc.accessMode }}
    - {{ $pvc.accessMode }}
    {{- else if or $pvc.nfs (contains "efs" ($pvc.storageClass | default "")) (and $pvc.csi (has $pvc.csi.driver (list "smb.csi.k8s.io" "efs.csi.aws.com" "s3.csi.aws.com"))) }}
    - ReadWriteMany
    {{- else }}
    - ReadWriteOnce
    {{- end }}
  capacity:
    {{- if or $pvc.nfs (contains "efs" ($pvc.storageClass | default "")) (and $pvc.csi (has $pvc.csi.driver (list "smb.csi.k8s.io" "efs.csi.aws.com" "s3.csi.aws.com"))) }}
    storage: 1Mi
    {{- else }}
    storage: {{ $pvc.size }}
    {{- end }}
  storageClassName: ""
  persistentVolumeReclaimPolicy: Retain
  {{- if $pvc.nfs }}
  mountOptions:
    {{- toYaml $pvc.nfs.mountOptions | nindent 4 }}
  nfs:
    {{- toYaml (omit $pvc.nfs "mountOptions") | nindent 4 }}
  {{- else if $pvc.csi }}
  {{- with $pvc.csi.mountOptions }}
  mountOptions:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  csi:
    {{- toYaml (omit $pvc.csi "mountOptions") | nindent 4 }}
  {{- end }}
{{- end }} {{/* End if $pvc.nfs or $pvc.csi */}}
{{- end }} {{/* End define "microservice.render-pvc" */}}
