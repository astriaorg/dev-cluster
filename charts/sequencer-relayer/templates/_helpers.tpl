{{/*
Namepsace to deploy elements into.
*/}}
{{- define "sequencer-relayer.namespace" -}}
{{- default .Release.Namespace .Values.global.namespaceOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "sequencer-relayer.image" -}}
{{ .Values.images.sequencer-relayer.repo }}:{{ if .Values.global.dev }}{{ .Values.images.sequencer-relayer.devTag }}{{ else }}{{ .Values.images.sequencer-relayer.tag }}{{ end }}
{{- end }}
