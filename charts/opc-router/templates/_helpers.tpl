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
Selector labels of the router workload and its Service. Kubernetes does not allow the selector of
an existing Deployment to change, and chart versions up to 1.0.4 put the chart version into it. A
release that already has its Deployment therefore keeps the selector it was created with; new
releases get labels that stay stable across chart versions. lookup is empty under helm template.
*/}}
{{- define "opc-router.workloadSelectorLabels" -}}
{{- $existing := lookup "apps/v1" "Deployment" .Release.Namespace (include "opc-router.fullname" .) -}}
{{- $matchLabels := dig "spec" "selector" "matchLabels" dict $existing -}}
{{- if $matchLabels -}}
{{- toYaml $matchLabels -}}
{{- else -}}
app.kubernetes.io/name: {{ include "opc-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: router
{{- end -}}
{{- end }}

{{/*
Stops an upgrade that would switch a Deployment applied server-side (Helm 4) from Kubernetes' default
rolling update to Recreate. The API added the rollingUpdate settings when it created the Deployment,
so no field manager owns them, and a server-side apply removes only fields its own manager owns: the
Deployment would be rejected after the resources applied before it were already updated.
*/}}
{{- define "opc-router.strategySwitchGuard" -}}
{{- $name := include "opc-router.fullname" . -}}
{{- $namespace := .Release.Namespace -}}
{{- $existing := lookup "apps/v1" "Deployment" $namespace $name -}}
{{- if dig "spec" "strategy" "rollingUpdate" nil $existing -}}
{{- $applied := false -}}
{{- $owned := false -}}
{{- range (dig "metadata" "managedFields" list $existing) -}}
{{- if eq .operation "Apply" -}}
{{- $applied = true -}}
{{- if hasKey (dig "fieldsV1" "f:spec" "f:strategy" dict .) "f:rollingUpdate" -}}
{{- $owned = true -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if and $applied (not $owned) -}}
{{- fail (printf `the Deployment %s still has the rolling update settings Kubernetes gave it at installation, and it is managed by server-side apply (Helm 4). This upgrade replaces the router pod with the strategy Recreate, and a server-side apply cannot remove those settings, so the upgrade would stop half-way. Nothing has been changed. Switch the Deployment to Recreate first, which does not restart the router:
  kubectl patch deployment %s -n %s --type merge -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
then repeat the upgrade. To keep a rolling update instead, set updateStrategy.type=RollingUpdate.` $name $name $namespace) -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Stops project.importMode=clear on the router images whose import cannot clear: from 5.5.6007 on, 5.6
and 5.7. The 5.5 hotfixes before 5.5.6007 are left out because nothing shows whether they carry the
defect. Any other tag keeps the warning of the installation notes.
*/}}
{{- define "opc-router.importClearGuard" -}}
{{- $tag := toString (.Values.image.tag | default .Chart.AppVersion) -}}
{{- $stops := regexMatch `^5\.[67]([.-]|$)` $tag -}}
{{- if regexMatch `^5\.5(-(amd64|arm64|arm|ferretdb))*$` $tag -}}
{{- $stops = true -}}
{{- end -}}
{{- if regexMatch `^5\.5\.[0-9]+\.` $tag -}}
{{- if ge (atoi (index (splitList "." $tag) 2)) 6007 -}}
{{- $stops = true -}}
{{- end -}}
{{- end -}}
{{- if $stops -}}
{{- fail (printf "project.importMode=clear cannot work with the router image %s: OPC Router 5.5 from 5.5.6007 on, 5.6 and 5.7 stop while clearing the configuration, and the web management never starts. Nothing has been changed. Use project.importMode=overwrite, the default." $tag) -}}
{{- end -}}
{{- end }}

{{/*
Labels of the router pod: the selector labels, completed by the common labels. Where both name the
same key, the selector's value wins, so a kept selector still matches its pods.
*/}}
{{- define "opc-router.podLabels" -}}
{{- $selector := include "opc-router.workloadSelectorLabels" . | fromYaml -}}
{{- $common := include "opc-router.labels" . | fromYaml -}}
{{- toYaml (merge $selector $common (dict "app.kubernetes.io/component" "router")) -}}
{{- end }}

{{/*
Requested size of a claim, called with (list $ "inray") or (list $ "log"): the configured capacity;
otherwise the size of the release's existing claim, because a bound claim cannot shrink and growing
it needs a storage class that allows expansion; otherwise the default for a new install. The data
claim holds the embedded database when the router runs without a separate MongoDB.
*/}}
{{- define "opc-router.claimCapacity" -}}
{{- $root := index . 0 -}}
{{- $claim := index . 1 -}}
{{- $configured := dig $claim "capacity" "" ($root.Values.claims | default dict) -}}
{{- if $configured -}}
{{- $configured -}}
{{- else -}}
{{- $name := ternary (include "opc-router.inray.fullname" $root) (include "opc-router.log.fullname" $root) (eq $claim "inray") -}}
{{- $existing := lookup "v1" "PersistentVolumeClaim" $root.Release.Namespace $name -}}
{{- $existingSize := dig "spec" "resources" "requests" "storage" "" $existing -}}
{{- if $existingSize -}}
{{- $existingSize -}}
{{- else if $root.Values.mongodb.deploy -}}
{{- ternary "1Gi" "4Gi" (eq $claim "inray") -}}
{{- else -}}
{{- ternary "10Gi" "6Gi" (eq $claim "inray") -}}
{{- end -}}
{{- end -}}
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
Connection string of the bundled MongoDB. The router supports only a single-member replica set: a
connection string with several hosts stops it from starting, and losing a member of a larger set
stalls it. The connection is direct: the router can initiate the set before the MongoDB chart does,
and then the member carries the pod's short host name, which resolves only inside the MongoDB pod. A
driver that follows the set's member names, as OPC Router 5.7's does, then finds no primary.
*/}}
{{- define "getMongoDB" -}}
{{- if gt (int .Values.mongodb.replicaCount) 1 -}}
{{- fail "mongodb.replicaCount must be 1: the router supports only a single-member MongoDB replica set. For high availability use the router's redundancy mode." -}}
{{- end -}}
"mongodb://{{ .Release.Name }}-mongodb-0.{{ .Release.Name }}-mongodb-headless/?directConnection=true"
{{- end }}