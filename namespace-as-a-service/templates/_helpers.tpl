
{{/*
Set the resource quota value for a given t-shirt size - Pods
*/}}
{{- define "namespace-as-a-service.resourceQuotaPodsValue" -}}
{{- $size := . | lower -}}
{{- if eq $size "small" -}}
8
{{- else if eq $size "medium" -}}
16
{{- else if eq $size "large" -}}
24
{{- else -}}
4
{{- end -}}
{{- end }}


{{/*
Set the resource quota value for a given t-shirt size - CPU Requests
*/}}
{{- define "namespace-as-a-service.resourceQuotaCPURequestsValue" -}}
{{- $size := . | lower -}}
{{- if eq $size "small" -}}
4
{{- else if eq $size "medium" -}}
8
{{- else if eq $size "large" -}}
16
{{- else -}}
2
{{- end -}}
{{- end }}


{{/*
Set the resource quota value for a given t-shirt size - CPU Limits
*/}}
{{- define "namespace-as-a-service.resourceQuotaCPULimitsValue" -}}
{{- $size := . | lower -}}
{{- if eq $size "small" -}}
8
{{- else if eq $size "medium" -}}
16
{{- else if eq $size "large" -}}
32
{{- else -}}
4
{{- end -}}
{{- end }}


{{/*
Set the resource quota value for a given t-shirt size - Memory Requests
*/}}
{{- define "namespace-as-a-service.resourceQuotaMemoryRequestsValue" -}}
{{- $size := . | lower -}}
{{- if eq $size "small" -}}
4Gi
{{- else if eq $size "medium" -}}
8Gi
{{- else if eq $size "large" -}}
16Gi
{{- else -}}
2Gi
{{- end -}}
{{- end }}


{{/*
Set the resource quota value for a given t-shirt size - Memory Limits
*/}}
{{- define "namespace-as-a-service.resourceQuotaMemoryLimitsValue" -}}
{{- $size := . | lower -}}
{{- if eq $size "small" -}}
8Gi
{{- else if eq $size "medium" -}}
16Gi
{{- else if eq $size "large" -}}
32Gi
{{- else -}}
4Gi
{{- end -}}
{{- end }}



{{/*
Expand the name of the chart.
*/}}
{{- define "namespace-as-a-service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "namespace-as-a-service.fullname" -}}
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
{{- define "namespace-as-a-service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "namespace-as-a-service.labels" -}}
helm.sh/chart: {{ include "namespace-as-a-service.chart" . }}
{{ include "namespace-as-a-service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "namespace-as-a-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namespace-as-a-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "namespace-as-a-service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "namespace-as-a-service.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
