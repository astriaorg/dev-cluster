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

{{/*
Define the k8s path to rpc service
*/}}
{{- define "celestiaNode.service.adresses.rpc" -}}
http://{{ include "celestiaNode.service.name" . }}.{{ .Values.global.namespace }}.svc.cluster.local:{{ .Values.ports.rpc }}
{{- end }}


{{/*
Is this a custom network?
*/}}
{{- define "celestiaNode.customNetwork" -}}
{{ eq .Values.config.network "custom" }}
{{- end }}

{{- define "test" -}}
{{ print include "celestiaNode.customNetwork" .}}
{{- end }}
