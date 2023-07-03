{{/*
  Required values
*/}}
{{- define "docker-image-pull-secret.required" -}}
  {{- required "imageCredentials is required." .Values.imageCredentials -}}
    {{- range .Values.imageCredentials -}}
      {{- required "imageCredentials[].registry is required." .registry -}}
      {{- required "imageCredentials[].username is required." .username -}}
      {{- required "imageCredentials[].accessToken is required." .accessToken -}}
    {{- end -}}
    {{/* Check for registry uniqueness */}}
    {{- $registries := list -}}
    {{- range .Values.imageCredentials -}}
      {{- $registries = append $registries .registry -}}
    {{- end -}}
    {{- required "All imageCredentials[].registry's must be unique." (or (eq (len $registries) (len ($registries | uniq))) nil) -}}
{{- end -}}
