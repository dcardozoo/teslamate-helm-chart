#!/usr/bin/env bash
# Install, test and uninstall the chart once per values file on the current kube-context.
# Requires the CloudNativePG operator to be installed in the cluster.
# Usage: scripts/e2e.sh ci/default-values.yaml [ci/minimal-values.yaml ...]
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE="${RELEASE:-teslamate}"
NAMESPACE="${NAMESPACE:-teslamate}"
TIMEOUT="${TIMEOUT:-15m}"
KEEP="${KEEP:-false}"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

dump() {
  log "Diagnostics"
  kubectl -n "$NAMESPACE" get all,clusters.postgresql.cnpg.io,pvc -o wide || true
  kubectl -n "$NAMESPACE" get events --sort-by=.lastTimestamp | tail -40 || true
  for pod in $(kubectl -n "$NAMESPACE" get pods -o name); do
    echo "--- $pod"; kubectl -n "$NAMESPACE" logs "$pod" --all-containers --tail=30 || true
  done
}

fixtures() {
  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "$NAMESPACE" create secret generic e2e-grafana-readonly --type=kubernetes.io/basic-auth \
    --from-literal=username=grafana --from-literal=password=e2e-grafana-password \
    --dry-run=client -o yaml | kubectl apply -f -
}

cleanup() {
  log "Uninstalling $RELEASE"
  helm uninstall "$RELEASE" -n "$NAMESPACE" --wait --timeout 10m
  if [[ -n "$(kubectl -n "$NAMESPACE" get clusters.postgresql.cnpg.io -o name 2>/dev/null)" ]]; then
    echo "helm uninstall left CNPG clusters behind" >&2; exit 1
  fi
  kubectl delete namespace "$NAMESPACE" --wait --timeout 10m --ignore-not-found
}

[[ $# -gt 0 ]] || { echo "usage: $0 <values-file>..." >&2; exit 2; }
kubectl get crd clusters.postgresql.cnpg.io >/dev/null 2>&1 \
  || { echo "CloudNativePG operator not found: install it first (https://cloudnative-pg.io/documentation/current/installation_upgrade/)" >&2; exit 1; }

for values in "$@"; do
  log "Scenario: $values (context: $(kubectl config current-context))"
  fixtures
  # keepOnUninstall=false so cleanup can verify the Cluster is removed with the release.
  if ! helm upgrade --install "$RELEASE" "$CHART_DIR" -n "$NAMESPACE" -f "$values" \
      --set database.cnpg.keepOnUninstall=false \
      --wait --timeout "$TIMEOUT"; then
    dump; exit 1
  fi
  if ! helm test "$RELEASE" -n "$NAMESPACE" --logs --timeout 5m; then
    dump; exit 1
  fi
  [[ "$KEEP" == "true" ]] || cleanup
done
log "All scenarios passed"
