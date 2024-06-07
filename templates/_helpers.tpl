{{/*
Expand the name of the chart.
*/}}
{{- define "textual.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "textual.fullname" -}}
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
{{- define "textual.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "textual.labels" -}}
helm.sh/chart: {{ include "textual.chart" . }}
{{ include "textual.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "textual.selectorLabels" -}}
app.kubernetes.io/name: {{ include "textual.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "textual.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "textual.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- else -}}
    {{ "" }}
{{- end -}}
{{- end }}

{{/*
Creates the log sharing sidecar container
*/}}
{{- define "textual.loggingSidecar" -}}
{{- $root := first . }}
{{- $values := $root.Values }}
{{- $logVolume := index . 1 }}
{{- $logDir := "/usr/bin/textual/logs_public" }}
{{- $env := ($values.log_collector).env }}
- name: vector
  image: quay.io/tonicai/log_collector
  imagePullPolicy: Always
  env:
    - name: VECTOR_SELF_NODE_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: spec.nodeName
    - name: VECTOR_SELF_POD_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.name
    - name: VECTOR_SELF_POD_NAMESPACE
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.namespace
    - name: LOG_COLLECTION_FOLDER
      value: "{{ $logDir }}"
    - name: ENABLE_LOG_COLLECTION
      value: "true"
    {{- range $key, $value := $env }}
    - name: {{ $key }}
      value: {{ $value | quote }}
    {{- end }}
  volumeMounts:
    - name: {{ $logVolume }}
      mountPath: "{{ $logDir }}"
{{- end }}