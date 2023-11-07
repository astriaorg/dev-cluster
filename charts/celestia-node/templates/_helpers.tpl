{{/*
Define the base label
*/}}
{{- define "baseLabel" -}}
{{- if .Values.config.labelPrefix }}{{ .Values.config.labelPrefix }}-{{- end }}{{ .Values.config.name }}-{{ .Values.config.type }}-{{ .Values.config.chainId }}
{{- end -}}
