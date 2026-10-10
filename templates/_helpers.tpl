{{- define "teslamate.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "teslamate.fullname" -}}
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

{{/* Component name: teslamate.componentName (dict "ctx" $ "component" "grafana") */}}
{{- define "teslamate.componentName" -}}
{{- printf "%s-%s" (include "teslamate.fullname" .ctx | trunc 50 | trimSuffix "-") .component }}
{{- end }}

{{- define "teslamate.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "teslamate.selectorLabels" -}}
app.kubernetes.io/name: {{ include "teslamate.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{- define "teslamate.labels" -}}
helm.sh/chart: {{ include "teslamate.chart" .ctx }}
{{ include "teslamate.selectorLabels" . }}
app.kubernetes.io/version: {{ .ctx.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
app.kubernetes.io/part-of: teslamate
{{- with .ctx.Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "teslamate.image" -}}
{{- printf "%s:%s" .image.repository (.image.tag | default .ctx.Chart.AppVersion | toString) }}
{{- end }}

{{- define "teslamate.imagePullSecrets" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/* ---------- Database ---------- */}}

{{- define "teslamate.cnpgEnabled" -}}
{{- if eq .Values.database.type "cnpg" }}true{{ end }}
{{- end }}

{{- define "teslamate.cnpg.clusterName" -}}
{{- include "teslamate.componentName" (dict "ctx" . "component" "db") }}
{{- end }}

{{- define "teslamate.cnpg.backupPlugin" -}}
barman-cloud.cloudnative-pg.io
{{- end }}

{{- define "teslamate.cnpg.annotations" -}}
{{- $a := deepCopy .extra }}
{{- if .ctx.Values.database.cnpg.keepOnUninstall }}
{{- $_ := set $a "helm.sh/resource-policy" "keep" }}
{{- end }}
{{- toYaml $a }}
{{- end }}

{{/* Drops empty strings/maps/lists from a map (one level deep). */}}
{{- define "teslamate.compact" -}}
{{- $out := dict }}
{{- range $k, $v := . }}{{ if $v }}{{ $_ := set $out $k $v }}{{ end }}{{ end }}
{{- toYaml $out }}
{{- end }}

{{- define "teslamate.db.host" -}}
{{- if include "teslamate.cnpgEnabled" . }}
{{- printf "%s-rw" (include "teslamate.cnpg.clusterName" .) }}
{{- else }}
{{- required "database.external.host is required when database.type=external" .Values.database.external.host }}
{{- end }}
{{- end }}

{{- define "teslamate.db.port" -}}
{{- if include "teslamate.cnpgEnabled" . }}5432{{ else }}{{ .Values.database.external.port }}{{ end }}
{{- end }}

{{- define "teslamate.db.name" -}}
{{- if include "teslamate.cnpgEnabled" . }}{{ .Values.database.cnpg.database }}{{ else }}{{ .Values.database.external.database }}{{ end }}
{{- end }}

{{/* Secret with username/password keys for the TeslaMate database owner. */}}
{{- define "teslamate.db.secretName" -}}
{{- if include "teslamate.cnpgEnabled" . }}
{{- printf "%s-app" (include "teslamate.cnpg.clusterName" .) }}
{{- else }}
{{- required "database.external.existingSecret is required when database.type=external" .Values.database.external.existingSecret }}
{{- end }}
{{- end }}

{{- define "teslamate.db.passwordKey" -}}
{{- if include "teslamate.cnpgEnabled" . }}password{{ else }}{{ .Values.database.external.existingSecretPasswordKey }}{{ end }}
{{- end }}

{{/* DATABASE_* env vars for TeslaMate. */}}
{{- define "teslamate.db.env" -}}
- name: DATABASE_HOST
  value: {{ include "teslamate.db.host" . | quote }}
- name: DATABASE_PORT
  value: {{ include "teslamate.db.port" . | quote }}
- name: DATABASE_NAME
  value: {{ include "teslamate.db.name" . | quote }}
{{- if include "teslamate.cnpgEnabled" . }}
- name: DATABASE_USER
  value: {{ .Values.database.cnpg.owner | quote }}
- name: DATABASE_SSL
  value: "true"
- name: DATABASE_SSL_CA_CERT_FILE
  value: /etc/teslamate/db-ca/ca.crt
{{- else }}
- name: DATABASE_USER
  value: {{ .Values.database.external.username | quote }}
- name: DATABASE_SSL
  value: {{ .Values.database.external.ssl | toString | quote }}
{{- end }}
- name: DATABASE_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "teslamate.db.secretName" . }}
      key: {{ include "teslamate.db.passwordKey" . }}
{{- end }}

{{/* ---------- TeslaMate ---------- */}}

{{- define "teslamate.encryptionKeySecretName" -}}
{{- if .Values.teslamate.existingSecret }}
{{- .Values.teslamate.existingSecret }}
{{- else }}
{{- include "teslamate.fullname" . }}
{{- end }}
{{- end }}

{{- define "teslamate.mqttHost" -}}
{{- if .Values.teslamate.mqtt.host }}
{{- .Values.teslamate.mqtt.host }}
{{- else if .Values.mosquitto.enabled }}
{{- include "teslamate.componentName" (dict "ctx" . "component" "mosquitto") }}
{{- else }}
{{- fail "teslamate.mqtt.host is required when mosquitto.enabled=false (or set teslamate.mqtt.enabled=false)" }}
{{- end }}
{{- end }}

{{/* ---------- Validation ---------- */}}

{{- define "teslamate.validate" -}}
{{- if not (has .Values.database.type (list "cnpg" "external")) }}
{{- fail "database.type must be one of: cnpg, external" }}
{{- end }}
{{- if and .Values.teslamate.enabled (not .Values.teslamate.existingSecret) (not .Values.teslamate.encryptionKey) }}
{{- fail "Set teslamate.encryptionKey or teslamate.existingSecret. Generate one with: openssl rand -base64 32" }}
{{- end }}
{{- if include "teslamate.cnpgEnabled" . }}
{{- if lt (int .Values.database.cnpg.instances) 2 }}
{{- fail "database.cnpg.instances must be at least 2 (one primary, one replica)" }}
{{- end }}
{{- if and .Values.database.cnpg.backup.enabled (not .Values.database.cnpg.backup.objectStore.destinationPath) }}
{{- fail "database.cnpg.backup.objectStore.destinationPath is required when backups are enabled" }}
{{- end }}
{{- if and .Values.grafana.readOnlyUser.enabled (not .Values.grafana.readOnlyUser.existingSecret) }}
{{- fail "grafana.readOnlyUser.existingSecret is required when grafana.readOnlyUser.enabled=true" }}
{{- end }}
{{- else }}
{{- if .Values.database.cnpg.backup.enabled }}
{{- fail "database.cnpg.backup.enabled only applies to database.type=cnpg; back up your external database yourself" }}
{{- end }}
{{- if .Values.grafana.readOnlyUser.enabled }}
{{- fail "grafana.readOnlyUser is only supported with database.type=cnpg" }}
{{- end }}
{{- end }}
{{- end }}
