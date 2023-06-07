{{/*
Create the labels for the manifests
*/}}
{{- define "create-labels" -}}
{{- $thisChart := index . 0 }}
{{- $thisRelease := index . 1 }}
{{- $thisValues := index . 2 }}
helm.sh/chart: "{{- printf "%s-%s" $thisChart.Name $thisChart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}"
app.kubernetes.io/name: {{ default $thisChart.Name | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ $thisRelease.Name }}
app.kubernetes.io/version: "{{ $thisChart.AppVersion }}"
app.kubernetes.io/managed-by: {{ $thisRelease.Service }}

{{- end }}


{{/*
Create the role bindings for the project. If we don't have any project rolebindings
we check for default role bindings
*/}}
{{- define "create-rolebindings" -}}
{{- $top := index . 0 }}
{{- $currentProjectname := index . 1 }}
{{- $current := index . 2 }}
{{- $roleBindings := "" }}
{{- $isEnabled := false }}

{{- if $current.roleSettings }}
  {{- if $current.roleSettings.enabled }}
    {{- $isEnabled = true }}
  {{- end }}
{{- end }}

{{- if not $isEnabled }}
  {{- if $top.Values.defaultSettings.roleSettings }}
    {{- if $top.Values.defaultSettings.roleSettings.enabled }}
      {{- $isEnabled = true }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $isEnabled }}
  {{- if $top.Values.defaultSettings.roleSettings }}
    {{- if $top.Values.defaultSettings.roleSettings.enabled }}
      {{- if $top.Values.defaultSettings.roleSettings.roleBindings }}
        {{- $roleBindings = $top.Values.defaultSettings.roleSettings.roleBindings }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $current.roleSettings }}
    {{- if $current.roleSettings.roleBindings }}
      {{- $roleBindings = $current.roleSettings.roleBindings }}
    {{- end }}
  {{- end }}

  {{- if $roleBindings }}
    {{- range $roleBindings }}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: "{{ $currentProjectname }}-{{ .role }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: "{{ .role }}"
subjects:
  {{- range .identities }}
  - apiGroup: rbac.authorization.k8s.io
    kind: "{{ .type }}"
    name: "{{ .name }}"
  {{- end }}

    {{- end }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Create the resource quota entries
*/}}
{{- define "create-resource-quota" -}}
{{- $top := index . 0 }}
{{- $currentProjectname := index . 1 }}
{{- $current := index . 2 }}
{{- $resourceQuota := "" }}
{{- $resources := "" }}
{{- $isEnabled := false }}

{{- if $current.resources }}
  {{- if $current.resources.enabled }}
    {{- $isEnabled = true }}
  {{- end }}
{{- end }}

{{- if not $isEnabled }}
  {{- if $top.Values.defaultSettings.resources }}
    {{- if $top.Values.defaultSettings.resources.enabled }}
      {{- $isEnabled = true }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $isEnabled }}
  {{- if $top.Values.defaultSettings.resources }}
    {{- if $top.Values.defaultSettings.resources.enabled }}
      {{- if $top.Values.defaultSettings.resources.quota }}
        {{- $resourceQuota = $top.Values.defaultSettings.resources.quota }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $current.resources }}
    {{- if $current.resources.quota }}
      {{- $resourceQuota = $current.resources.quota }}
    {{- end }}
  {{- end }}

  {{- if $resourceQuota }}
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: "{{ $currentProjectname }}-quota"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
{{ $resourceQuota | toYaml | indent 2 }}
  {{- end }}
{{- end }}
{{- end }}


{{/*
Create the network policies. We create some defaults + specific ones configured
via the defaults or the project definition
*/}}
{{- define "create-network-policy" -}}
{{- $top := index . 0 }}
{{- $currentProjectname := index . 1 }}
{{- $current := index . 2 }}
{{- $networkPolicies := "" }}
{{- $resourceQuota := "" }}
{{- $isEnabled := false }}

{{- if $current.networkSettings }}
  {{- if $current.networkSettings.enabled }}
    {{- $isEnabled = true }}
  {{- end }}
{{- end }}

{{- if not $isEnabled }}
  {{- if $top.Values.defaultSettings.networkSettings }}
    {{- if $top.Values.defaultSettings.networkSettings.enabled }}
      {{- $isEnabled = true }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $isEnabled }}
  {{- if $top.Values.defaultSettings.networkSettings }}
    {{- if $top.Values.defaultSettings.networkSettings.enabled }}
      {{- if $top.Values.defaultSettings.networkSettings.networkPolicies }}
        {{- $networkPolicies = $top.Values.defaultSettings.networkSettings.networkPolicies }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $current.networkSettings }}
    {{- if $current.networkSettings.networkPolicies }}
      {{- $networkPolicies = $current.networkSettings.networkPolicies }}
    {{- end }}
  {{- end }}


{{/*
Ingress rules
*/}}
  {{- if $networkPolicies.ingress }}
    {{- if $networkPolicies.ingress.fromNamespaces }}
      {{- range $networkPolicies.ingress.fromNamespaces }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-namespace-{{ .namespace }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  {{- if not .podSelectors }}
  podSelector: {}
  {{- else }}
  podSelector:
    matchExpressions:
    {{- range .podSelectors }}
      - key: {{ .labelName }}
        operator: In
        values:
          - {{ .labelValue }}
    {{- end }}
  {{- end }}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - namespaceSelector:
          matchExpressions:
          {{- range .labels }}
            - key: {{ .labelName }}
              operator: In
              values:
                - {{ .labelValue }}
          {{- end }}
      {{- end }}
    {{- end }}
{{/*
Ingress podSelector rules
*/}}
    {{- if $networkPolicies.ingress.fromPods }}
      {{- range $networkPolicies.ingress.fromPods }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-pod-{{ .podName }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  {{- if not .podSelectors }}
  podSelector: {}
  {{- else }}
  podSelector:
    matchExpressions:
    {{- range .podSelectors }}
      - key: {{ .labelName }}
        operator: In
        values:
          - {{ .labelValue }}
    {{- end }}
  {{- end }}
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchExpressions:
          {{- range .labels }}
            - key: {{ .labelName }}
              operator: In
              values:
                - {{ .labelValue }}
          {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{/*
Egress namespace rules
*/}}
  {{- if $networkPolicies.egress }}
    {{- if $networkPolicies.egress.toNamespaces }}
      {{- range $networkPolicies.egress.toNamespaces }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-to-namespace-{{ .namespace }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  {{- if not .podSelectors }}
  podSelector: {}
  {{- else }}
  podSelector:
    matchExpressions:
    {{- range .podSelectors }}
      - key: {{ .labelName }}
        operator: In
        values:
          - {{ .labelValue }}
    {{- end }}
  {{- end }}
  policyTypes:
    - Egress
  egress:
    - to:
      - namespaceSelector:
          matchExpressions:
          {{- range .labels }}
            - key: {{ .labelName }}
              operator: In
              values:
                - {{ .labelValue }}
          {{- end }}
      {{- end }}
    {{- end }}
{{/*
Egress podSelector rules
*/}}
    {{- if $networkPolicies.egress.toPods }}
      {{- range $networkPolicies.egress.toPods }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-to-pod-{{ .podName }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  {{- if not .podSelectors }}
  podSelector: {}
  {{- else }}
  podSelector:
    matchExpressions:
    {{- range .podSelectors }}
      - key: {{ .labelName }}
        operator: In
        values:
          - {{ .labelValue }}
    {{- end }}
  {{- end }}
  policyTypes:
    - Egress
  egress:
    - to:
      - podSelector:
          matchExpressions:
          {{- range .labels }}
            - key: {{ .labelName }}
              operator: In
              values:
                - {{ .labelValue }}
          {{- end }}
      {{- end }}
    {{- end }}
{{/*
Egress CIDRs rules
*/}}
    {{- if $networkPolicies.egress.toCidrs }}
      {{- range $networkPolicies.egress.toCidrs }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-to-ip-{{ .cidrName }}"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  {{- if not .podSelectors }}
  podSelector: {}
  {{- else }}
  podSelector:
    matchExpressions:
    {{- range .podSelectors }}
      - key: {{ .labelName }}
        operator: In
        values:
          - {{ .labelValue }}
    {{- end }}
  {{- end }}
  policyTypes:
    - Egress
  egress:
    - to:
      {{- range .cidr }}
      - ipBlock:
          cidr: {{ . }}
      {{- end }}
      ports:
      {{- range .ports}}
        - protocol: {{ .protocol}}
          port: {{ .port }}
      {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-to-same-namespace"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  podSelector: {}
  ingress:
    - from:
      - podSelector: {}
  egress:
    - to:
      - podSelector: {}
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-openshift-ingress"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            network.openshift.io/policy-group: ingress
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-router"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            policy-group.network.openshift.io/ingress: ""
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-hostnetwork"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            policy-group.network.openshift.io/host-network: ""
  podSelector: {}
  policyTypes:
    - Ingress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-kube-apiserver-operator"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: openshift-kube-apiserver-operator
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-from-openshift-monitoring"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            network.openshift.io/policy-group: monitoring
  podSelector: {}
  policyTypes:
    - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-allow-openshift-logging"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: openshift-logging
  egress:
    - to:
      - namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: openshift-logging

  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: "{{ $currentProjectname }}-deny-all-by-default"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
{{- end }}
{{- end }}


{{/*
Create the limitRange entries
*/}}
{{- define "create-limit-ranges" -}}
{{- $top := index . 0 }}
{{- $currentProjectname := index . 1 }}
{{- $current := index . 2 }}
{{- $limitRanges := "" }}
{{- $isEnabled := false }}

{{- if $current.limitRanges }}
  {{- if $current.limitRanges.enabled }}
    {{- $isEnabled = true }}
  {{- end }}
{{- end }}

{{- if not $isEnabled }}
  {{- if $top.Values.defaultSettings.limitRanges }}
    {{- if $top.Values.defaultSettings.limitRanges.enabled }}
      {{- $isEnabled = true }}
    {{- end }}
  {{- end }}
{{- end }}

{{- if $isEnabled }}
  {{- if $top.Values.defaultSettings.limitRanges }}
    {{- if $top.Values.defaultSettings.limitRanges.enabled }}
      {{- if $top.Values.defaultSettings.limitRanges.limits }}
        {{- $limitRanges = $top.Values.defaultSettings.limitRanges.limits }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $current.limitRanges }}
    {{- if $current.limitRanges.limits }}
      {{- $limitRanges = $current.limitRanges.limits }}
    {{- end }}
  {{- end }}

  {{- if $limitRanges }}
---
apiVersion: v1
kind: LimitRange
metadata:
  name: "{{ $currentProjectname }}-limit-ranges"
  namespace: "{{ $currentProjectname }}"
  labels:
{{- include "create-labels" (list $top.Chart $top.Release $top.Values ) | indent 4 }}
spec:
  limits:
{{ $limitRanges | toYaml | indent 4 }}
  {{- end }}
{{- end }}
{{- end }}
