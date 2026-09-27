{{- define "laravel-app.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "laravel-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "laravel-app.selector" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "laravel-app.secretName" -}}
{{- .Values.existingSecret | default (printf "%s-env" (include "laravel-app.fullname" .)) -}}
{{- end -}}

{{/* Env items shared by every PHP container: web, worker, scheduler, migrations */}}
{{- define "laravel-app.envItems" -}}
{{- range $k, $v := .Values.env }}
- name: {{ $k }}
  value: {{ $v | quote }}
{{- end }}
{{- end -}}

{{- define "laravel-app.phpEnv" -}}
env:
  {{- include "laravel-app.envItems" . | nindent 2 }}
envFrom:
  - secretRef:
      name: {{ include "laravel-app.secretName" . }}
{{- end -}}

{{- define "laravel-app.fpmImage" -}}
{{ .Values.image.fpm.repository }}:{{ .Values.image.fpm.tag }}
{{- end -}}
