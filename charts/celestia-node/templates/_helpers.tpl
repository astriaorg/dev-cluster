{{/*
Define the base label
*/}}
{{- define "baseLabel" -}}
{{ .Values.config.name }}-{{ .Values.config.type }}-{{ .Values.config.chainId }}
{{- end -}}
