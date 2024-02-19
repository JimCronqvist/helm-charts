{{- if .Values.externalNames }}
{{- range .Values.externalNames }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  namespace: {{ .namespace | default $.Release.Namespace }}
  labels:
    {{- include "external-name.labels" $ | nindent 4 }}
  type: ExternalName
  externalName: {{ .externalName }}
---
{{- end }}
{{- end }}
