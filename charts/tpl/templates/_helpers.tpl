{{/*
Expand the name of the chart.
*/}}
{{- define "tpl.name" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- default $chart.Name $top.Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tpl.fullname" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- if $top.Values.fullnameOverride }}
{{- $top.Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default $chart.Name $top.Values.nameOverride }}
{{- if contains $name $release.Name }}
{{- $release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" $release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tpl.chart" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- printf "%s-%s" $chart.Name $chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tpl.labels" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- $deploymentName := index . 3 -}}
helm.sh/chart: {{ include "tpl.chart" (list $top $chart $release) }}
{{- if $chart.AppVersion }}
app.kubernetes.io/version: {{ $chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $release.Service }}
app.kubernetes.io/name: {{ include "tpl.name" (list $top $chart $release) }}
app.kubernetes.io/instance: {{ $release.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tpl.selectorLabels" -}}
{{- $top := index . 0 }}
{{- $chart := index . 1 }}
{{- $release := index . 2 }}
{{- $deploymentName := index . 3 -}}
app: {{ $deploymentName }}
deployment: {{ $deploymentName }}
{{- end }}

{{/*
Create YAML for probes
*/}}
{{- define "tpl.probes" -}}
{{- $probeValues := index . 0 }}
{{- $httpPort := index . 1 }}
{{- $httpsPort := index . 2 }}
{{- if $probeValues.method }}
{{- if eq $probeValues.method "httpGet" -}}
httpGet: 
  {{- if $probeValues.httpHeaders }}
  httpHeaders:
  {{- toYaml $probeValues.httpHeaders | nindent 4 }}
  {{- end }}
  path: {{ $probeValues.path }}
  {{- if eq $probeValues.scheme "HTTP" }}
  port: {{ $httpPort }}
  {{- else }}
  port: {{ $httpsPort }}
  {{- end }}
  scheme: {{ $probeValues.scheme }}
{{- end }}
{{- end }}
failureThreshold: {{ $probeValues.failureThreshold | default "3"}}
timeoutSeconds: {{ $probeValues.timeoutSeconds | default "1"}}
periodSeconds: {{ $probeValues.periodSeconds | default "10"}}
successThreshold: {{ $probeValues.successThreshold | default "1"}}
{{- end }}