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

{{- define "textual.dbPasswordSecretRef" -}}
name: {{ .Values.textualDatabase.existingSecret | default "textual-db-password" }}
key: {{ .Values.textualDatabase.existingSecretKey | default "password" }}
{{- end }}

{{- define "textual.licenseSecretRef" -}}
name: {{ .Values.solarLicenseExistingSecret | default "solar-license-secret" }}
key: {{ .Values.solarLicenseExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.encryptionSecretRef" -}}
name: {{ .Values.textualEncryptionSecretExistingSecret | default "textual-encryption-secret" }}
key: {{ .Values.textualEncryptionSecretExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.openAiApiKeySecretRef" -}}
name: {{ .Values.openAiApiKeyExistingSecret | default "openai-api-key" }}
key: {{ .Values.openAiApiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.chatApiKeySecretRef" -}}
name: {{ .Values.chatApiKeyExistingSecret | default "chat-api-key" }}
key: {{ .Values.chatApiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.llmProviderOpenAiApiKeySecretRef" -}}
name: {{ ((.Values.llmProvider).openai).apiKeyExistingSecret | default "llm-provider-openai-api-key" }}
key: {{ ((.Values.llmProvider).openai).apiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.llmProviderGoogleAiStudioApiKeySecretRef" -}}
name: {{ ((.Values.llmProvider).googleAiStudio).apiKeyExistingSecret | default "llm-provider-google-ai-studio-api-key" }}
key: {{ ((.Values.llmProvider).googleAiStudio).apiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.llmProviderVertexAiApiKeySecretRef" -}}
name: {{ ((.Values.llmProvider).vertexAi).apiKeyExistingSecret | default "llm-provider-vertex-ai-api-key" }}
key: {{ ((.Values.llmProvider).vertexAi).apiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.googleClientSecretRef" -}}
name: {{ .Values.googleClientSecretExistingSecret | default "google-sso-client-secret" }}
key: {{ .Values.googleClientSecretExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.githubClientSecretRef" -}}
name: {{ .Values.githubClientSecretExistingSecret | default "github-sso-client-secret" }}
key: {{ .Values.githubClientSecretExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.azureClientSecretRef" -}}
name: {{ .Values.azureClientSecretExistingSecret | default "azure-sso-client-secret" }}
key: {{ .Values.azureClientSecretExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.keycloakClientSecretRef" -}}
name: {{ .Values.keycloakClientSecretExistingSecret | default "keycloak-sso-client-secret" }}
key: {{ .Values.keycloakClientSecretExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.azureDocIntelligenceKeySecretRef" -}}
name: {{ .Values.azureDocIntelligenceKeyExistingSecret | default "azure-document-intelligence-key-secret" }}
key: {{ .Values.azureDocIntelligenceKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.amplitudeApiKeySecretRef" -}}
name: {{ .Values.amplitudeApiKeyExistingSecret | default "amplitude-api-key" }}
key: {{ .Values.amplitudeApiKeyExistingSecretKey | default "secret" }}
{{- end }}

{{- define "textual.analyticBackendSaltSecretRef" -}}
name: {{ .Values.analyticBackendSaltExistingSecret | default "analytic-backend-salt" }}
key: {{ .Values.analyticBackendSaltExistingSecretKey | default "secret" }}
{{- end }}

{{/*
Analytics runtime env vars for API and worker pods.

These secrets are intentionally runtime-only so release images do not contain
Amplitude credentials in Dockerfile ENV, image config, or image history.
*/}}
{{- define "textual.analyticsEnv" -}}
{{- if or .Values.amplitudeApiKey .Values.amplitudeApiKeyExistingSecret }}
- name: AMPLITUDE_API_KEY
  valueFrom:
    secretKeyRef:
      {{- include "textual.amplitudeApiKeySecretRef" . | nindent 6 }}
{{- end }}
{{- if or .Values.analyticBackendSalt .Values.analyticBackendSaltExistingSecret }}
- name: ANALYTIC_BACKEND_SALT
  valueFrom:
    secretKeyRef:
      {{- include "textual.analyticBackendSaltSecretRef" . | nindent 6 }}
{{- end }}
{{- end }}

{{/*
LLM provider credentials and feature config env vars.

Supports both new structured config (llmProvider.*, defaultLlmProvider, etc.) and legacy
flat config (chatModelEndpoint, chatApiKey). Raises a hard error if both are present on
the same deployment to prevent silent misconfiguration.

For new config, API keys can be supplied as inline values (apiKey) or via an existing
Kubernetes Secret (existingSecret + existingSecretKey).

Usage: {{- include "textual.llmEnv" . | nindent 10 }}
*/}}
{{- define "textual.llmEnv" -}}
{{- $v := .Values -}}

{{/* Hard error if legacy chat config and new config are both set */}}
{{- if and (or $v.chatModelEndpoint $v.chatApiKey $v.chatApiKeyExistingSecret) (or $v.defaultLlmProvider $v.llmProvider) -}}
  {{- fail "LLM config conflict: chatModelEndpoint/chatApiKey (legacy) cannot be used alongside defaultLlmProvider/llmProvider (new). Remove the legacy chat vars to migrate to the new config." -}}
{{- end -}}

{{/* New LLM provider credentials — configure only the providers you use */}}
{{- with ($v.llmProvider).openai }}
  {{- if or .apiKey .apiKeyExistingSecret }}
- name: LLM_PROVIDER_OPEN_AI_API_KEY
  valueFrom:
    secretKeyRef:
      {{- include "textual.llmProviderOpenAiApiKeySecretRef" $ | nindent 6 }}
  {{- end }}
  {{- if .url }}
- name: LLM_PROVIDER_OPEN_AI_URL
  value: {{ .url | quote }}
  {{- end }}
{{- end }}
{{- with ($v.llmProvider).googleAiStudio }}
  {{- if or .apiKey .apiKeyExistingSecret }}
- name: LLM_PROVIDER_GOOGLE_AI_STUDIO_API_KEY
  valueFrom:
    secretKeyRef:
      {{- include "textual.llmProviderGoogleAiStudioApiKeySecretRef" $ | nindent 6 }}
  {{- end }}
  {{- if .url }}
- name: LLM_PROVIDER_GOOGLE_AI_STUDIO_URL
  value: {{ .url | quote }}
  {{- end }}
{{- end }}
{{- with ($v.llmProvider).vertexAi }}
  {{- if or .apiKey .apiKeyExistingSecret }}
- name: LLM_PROVIDER_VERTEX_AI_API_KEY
  valueFrom:
    secretKeyRef:
      {{- include "textual.llmProviderVertexAiApiKeySecretRef" $ | nindent 6 }}
  {{- end }}
  {{- if .url }}
- name: LLM_PROVIDER_VERTEX_AI_URL
  value: {{ .url | quote }}
  {{- end }}
{{- end }}
{{- with ($v.llmProvider).bedrock }}
  {{- if .region }}
- name: LLM_PROVIDER_AMAZON_BEDROCK_REGION
  value: {{ .region | quote }}
  {{- end }}
  {{- if .maxTokens }}
- name: LLM_PROVIDER_AMAZON_BEDROCK_MAX_TOKENS
  value: {{ .maxTokens | quote }}
  {{- end }}
{{- end }}

{{/* Shared defaults — apply to all features unless overridden per-feature */}}
{{- if $v.defaultLlmProvider }}
- name: LLM_DEFAULT_PROVIDER
  value: {{ $v.defaultLlmProvider | quote }}
{{- end }}
{{- if $v.defaultLlmModel }}
- name: LLM_DEFAULT_MODEL_NAME
  value: {{ $v.defaultLlmModel | quote }}
{{- end }}

{{/* Per-feature overrides */}}
{{- if $v.llmSynthesisProvider }}
- name: MODEL_BASED_ENTITIES_LLM_PROVIDER
  value: {{ $v.llmSynthesisProvider | quote }}
{{- end }}
{{- if $v.llmSynthesisModelName }}
- name: MODEL_BASED_ENTITIES_LLM_MODEL_NAME
  value: {{ $v.llmSynthesisModelName | quote }}
{{- end }}
{{- if $v.chatLlmProvider }}
- name: CHAT_LLM_PROVIDER
  value: {{ $v.chatLlmProvider | quote }}
{{- end }}
{{- if $v.chatModelName }}
- name: CHAT_MODEL_NAME
  value: {{ $v.chatModelName | quote }}
{{- end }}

{{/* Legacy chat config — kept for backward compatibility; conflicts with new config are caught above */}}
{{- if $v.chatModelEndpoint }}
- name: CHAT_MODEL_ENDPOINT
  value: {{ $v.chatModelEndpoint | quote }}
{{- end }}
{{- if or $v.chatApiKey $v.chatApiKeyExistingSecret }}
- name: CHAT_API_KEY
  valueFrom:
    secretKeyRef:
      {{- include "textual.chatApiKeySecretRef" . | nindent 6 }}
{{- end }}
{{- end -}}

{{/*
Custom CA volume: mounts a customer-supplied ConfigMap of PEM-encoded CAs.
Emitted only when .Values.customCa.enabled is true. Use at the volumes: list of a Deployment.
*/}}
{{- define "textual.customCa.volume" -}}
{{- if (.Values.customCa).enabled }}
- name: custom-ca-source
  configMap:
    name: {{ required "customCa.configMapName must be set when customCa.enabled is true" .Values.customCa.configMapName }}
    optional: true
{{- end }}
{{- end }}

{{/*
Custom CA mount path: single source of truth for the path used by both the volumeMount and the env var.
*/}}
{{- define "textual.customCa.path" -}}
{{- (.Values.customCa).mountPath | default "/etc/tonic/textual/trusted-ca-certs" -}}
{{- end }}

{{/*
Custom CA volumeMount: mounts the ConfigMap read-only at the configured path.
Emitted only when .Values.customCa.enabled is true. Use at the main container's volumeMounts: list.
*/}}
{{- define "textual.customCa.volumeMount" -}}
{{- if (.Values.customCa).enabled }}
- name: custom-ca-source
  mountPath: {{ include "textual.customCa.path" . }}
  readOnly: true
{{- end }}
{{- end }}

{{/*
Custom CA env: tells the app where to find the cert files at startup.
Emitted only when .Values.customCa.enabled is true. Use at the main container's env: list.
*/}}
{{- define "textual.customCa.env" -}}
{{- if (.Values.customCa).enabled }}
- name: SOLAR_CUSTOM_CA_PATH
  value: {{ include "textual.customCa.path" . | quote }}
{{- end }}
{{- end }}
