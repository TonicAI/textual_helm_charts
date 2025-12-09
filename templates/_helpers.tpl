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
Combine all labels: chart-wide (.Values.allLabels)
Usage:
  {{- include "textual.allLabels" (list $ (dict "app" "my-app")) | nindent 4 }}
*/}}
{{- define "textual.allLabels" -}}
{{- $top := first . -}}
{{- $labels := dict -}}

{{/* Merge global/allLabels first */}}
{{- if $top.Values.allLabels -}}
  {{- $labels = mergeOverwrite $labels $top.Values.allLabels -}}
{{- end -}}

{{/* Merge any labels passed into the helper */}}
{{- if (gt (len .) 1) -}}
  {{- $these := (index . 1) -}}
  {{- $labels = mergeOverwrite $labels $these -}}
{{- end -}}

{{/* Sort keys for deterministic output */}}
{{- $keys := keys $labels | sortAlpha -}}
{{- $yamlStrings := list -}}
{{- range $k := $keys -}}
  {{- $v := index $labels $k -}}
  {{- $yamlStrings = append $yamlStrings (printf "%s: %q" $k $v) -}}
{{- end -}}

{{- join "\n" $yamlStrings -}}
{{- end -}}

{{/*
Combine all annotations: chart-wide (.Values.allAnnotations)
Usage:
  {{- include "textual.allAnnotations" (list $ (dict "key" "value")) | nindent 4 }}
*/}}
{{- define "textual.allAnnotations" -}}
{{- $top := first . -}}
{{- $annotations := dict -}}

{{- if $top.Values.allAnnotations -}}
  {{- $annotations = mergeOverwrite $annotations $top.Values.allAnnotations -}}
{{- end -}}

{{- if (gt (len .) 1) -}}
  {{- $these := (index . 1) -}}
  {{- $annotations = mergeOverwrite $annotations $these -}}
{{- end -}}

{{- $keys := keys $annotations | sortAlpha -}}
{{- $yamlStrings := list -}}
{{- range $k := $keys -}}
  {{- $v := index $annotations $k -}}
  {{- $yamlStrings = append $yamlStrings (printf "%s: %q" $k $v) -}}
{{- end -}}

{{- join "\n" $yamlStrings -}}
{{- end -}}

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
  {{- if  ($values.log_collector).image }}
  image: {{ $values.log_collector.image }}
  {{ else }}
  image: quay.io/tonicai/log_collector
  {{ end -}}
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

{{/*
Tolerances
*/}}
{{- define "textual.tolerations" -}}
{{- $top := first . }}
{{- $tolerations := list }}
{{- if ($top.Values).tolerations }}
{{- $tolerations = concat $tolerations $top.Values.tolerations }}
{{- end }}
{{- if (gt (len .) 1) }}
{{- $these := (index . 1) }}
{{- if $these }}
{{- $tolerations = concat $tolerations $these }}
{{- end }}
{{- end }}
{{- if $tolerations }}
{{- toYaml $tolerations }}
{{- end }}
{{- end }}

{{- define "textual.nodeSelector" -}}
{{- $top := first . }}
{{- $selectors := dict }}
{{- if ($top.Values).nodeSelector }}
{{- $selectors = merge $selectors $top.Values.nodeSelector }}
{{- if (gt (len .) 1) }}
{{- $selectors = merge $selectors (index . 1) }}
{{- end }}
{{- if $selectors }}
{{- $selectors | toYaml }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Select the busybox image
*/}}
{{- define "textual.busyboxImage" -}}
{{- if .Values.busyboxImage }}
{{- .Values.busyboxImage | indent 1 -}}
{{ else }}
{{- print " busybox" -}}
{{ end -}}
{{- end }}

