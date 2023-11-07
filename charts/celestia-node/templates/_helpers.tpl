{{/*
Define the base label
*/}}
{{- define "celestiaNode.baseLabel" -}}
{{- if .Values.config.labelPrefix }}{{ .Values.config.labelPrefix }}-{{- end }}{{ .Values.config.name }}-{{ .Values.config.type }}-{{ .Values.config.chainId }}
{{- end }}
{{/*
Define the service name
*/}}
{{- define "celestiaNode.service.name" -}}
{{ include "celestiaNode.baseLabel" . }}-service
{{- end }}

{{- define "celestiaNode.service.adresses.rpc" -}}
http://{{ include "celestiaNode.service.name" . }}.{{ .Values.global.namespace }}.svc.cluster.local:{{ .Values.ports.rpc }}
{{- end }}
