{{/*
Expand the name of the chart.
*/}}
{{- define "opc-router.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opc-router.fullname" -}}
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

{{- define "opc-router.redundancy.fullname" -}}
{{- include "opc-router.fullname" . | cat "redundant" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opc-router.inray.fullname" -}}
{{- include "opc-router.fullname" . | cat "inray" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opc-router.log.fullname" -}}
{{- include "opc-router.fullname" . | cat "log" | replace " " "-" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opc-router.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opc-router.labels" -}}
helm.sh/chart: {{ include "opc-router.chart" . }}
app.kubernetes.io/name: {{ include "opc-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opc-router.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
statefulset.kubernetes.io/pod-name: {{ include "opc-router.fullname" . }}
{{- end }}

{{/*
Original selector labels
*/}}
{{- define "opc-router.originalSelectorLabels" -}}
originForRedundency: {{ include "opc-router.redundancy.fullname" . }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "opc-router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opc-router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the connection string for the mongodb(s)
*/}}
{{- define "getMongoDB" }}
{{- $addresses := int .Values.mongodb.replicaCount | until }}
{{- range $addresses -}}
{{- if (ne . 0) -}}
,
{{- end -}}
"mongodb://{{ $.Release.Name }}-mongodb-{{ . }}.{{ $.Release.Name }}-mongodb-headless"
{{- end }}
{{- end }}