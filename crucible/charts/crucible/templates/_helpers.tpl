{{/*
Chart name and version as used by the chart label.
*/}}
{{- define "crucible-local.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "crucible-local.labels" -}}
helm.sh/chart: {{ include "crucible-local.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Gitea image reference (for use in jobs that need the gitea binary).
Delegates to the Bitnami gitea subchart's image helper.
*/}}
{{- define "crucible-local.gitea.image" -}}
{{- $giteaCtx := dict
      "Values"       .Values.gitea
      "Chart"        .Subcharts.gitea
      "Release"      .Release
      "Capabilities" .Capabilities
  -}}
{{- include "gitea.image" $giteaCtx -}}
{{- end -}}
