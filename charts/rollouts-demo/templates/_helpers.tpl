{{- define "rollouts-demo.name" -}}
{{- .Release.Name }}
{{- end -}}

{{- define "rollouts-demo.labels" -}}
app.kubernetes.io/name: {{ include "rollouts-demo.name" . }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "rollouts-demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rollouts-demo.name" . }}
{{- end -}}
