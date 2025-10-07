{{/*
Expand the name of the chart.
*/}}
{{- define "localgpt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "localgpt.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "localgpt.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "localgpt.labels" -}}
helm.sh/chart: {{ include "localgpt.chart" . }}
{{ include "localgpt.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "localgpt.selectorLabels" -}}
app.kubernetes.io/name: {{ include "localgpt.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component labels
*/}}
{{- define "localgpt.componentLabels" -}}
{{ include "localgpt.labels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Component selector labels
*/}}
{{- define "localgpt.componentSelectorLabels" -}}
{{ include "localgpt.selectorLabels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "localgpt.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "localgpt.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create image reference
*/}}
{{- define "localgpt.image" -}}
{{- if .registry }}
{{- printf "%s/%s:%s" .registry .repository .tag }}
{{- else }}
{{- printf "%s:%s" .repository .tag }}
{{- end }}
{{- end }}

{{/*
Get Ollama host URL
*/}}
{{- define "localgpt.ollamaHost" -}}
{{- if .Values.ollama.enabled }}
{{- printf "http://%s-ollama:%d" (include "localgpt.fullname" .) (int .Values.ollama.service.port) }}
{{- else if .Values.ollama.external.enabled }}
{{- .Values.ollama.external.host }}
{{- else }}
{{- printf "http://%s-ollama:%d" (include "localgpt.fullname" .) (int .Values.ollama.service.port) }}
{{- end }}
{{- end }}

{{/*
Image pull policy
*/}}
{{- define "localgpt.imagePullPolicy" -}}
{{- .pullPolicy | default .Values.global.imagePullPolicy | default "Always" }}
{{- end }}
