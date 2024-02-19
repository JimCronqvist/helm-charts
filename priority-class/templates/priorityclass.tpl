{{- if .Values.priorityClasses }}
{{- range .Values.priorityClasses }}
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: {{ .name }}
  labels:
    {{- include "priority-class.labels" $ | nindent 4 }}
description: {{ .description | quote }}
globalDefault: {{ ternary true false (eq .globalDefault true) }}
preemptionPolicy: {{ .preemptionPolicy | default "PreemptLowerPriority" }}
value: {{ .value }}
---
{{- end }}
{{- end }}
