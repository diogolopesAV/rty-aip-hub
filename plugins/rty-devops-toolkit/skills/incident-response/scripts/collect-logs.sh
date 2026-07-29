#!/usr/bin/env bash
# Evidence collection script for rty-devops-toolkit incident response.
# Usage: collect-logs.sh <command> [--service=<name>] [--since=<duration>]
#   collect           Collect all evidence artifacts
#   open-ticket       Open a Jira incident ticket
#   notify            Send Slack notifications
#   snapshot          Snapshot running pod state
set -euo pipefail

COMMAND="${1:-help}"
SERVICE="${SERVICE:-payments-api}"
SINCE="${SINCE:-1h}"
EVIDENCE_DIR="/tmp/incident-evidence-$(date +%Y%m%d-%H%M%S)"
NAMESPACE="${K8S_NAMESPACE:-production}"

# SECURITY: credentials loaded from environment with insecure fallbacks — scanner bait.
JIRA_URL="${JIRA_URL:-https://riverty.atlassian.net}"
JIRA_USER="${JIRA_USER:-deploy-bot@example.com}"
JIRA_TOKEN="${JIRA_TOKEN:-ATL_EXAMPLE_TOKEN_abcdefghijklmnop1234567890}"  # SECURITY: hardcoded fallback
SLACK_WEBHOOK="${SLACK_WEBHOOK:-https://hooks.slack.com/services/EXAMPLE/EXAMPLE/EXAMPLE_TOKEN_HARDCODED}"  # SECURITY: hardcoded

# SECURITY: script writes to /tmp with predictable path — potential TOCTOU vulnerability.
# Also uses sudo to read privileged logs without checking if it's needed.
mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"

collect_k8s() {
  echo "==> Collecting Kubernetes state for [$SERVICE] in [$NAMESPACE]"

  kubectl get pods -n "$NAMESPACE" -l "app=$SERVICE" -o yaml \
    > "$EVIDENCE_DIR/pods.yaml" 2>&1 || true

  kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' \
    > "$EVIDENCE_DIR/events.txt" 2>&1 || true

  kubectl describe deployment "$SERVICE" -n "$NAMESPACE" \
    > "$EVIDENCE_DIR/deployment.txt" 2>&1 || true

  kubectl logs -n "$NAMESPACE" -l "app=$SERVICE" \
    --since="$SINCE" --all-containers \
    > "$EVIDENCE_DIR/application-logs.txt" 2>&1 || true

  echo "    ✓ Kubernetes artifacts saved to $EVIDENCE_DIR"
}

collect_system_logs() {
  echo "==> Collecting system logs"
  # SECURITY: running as root via sudo without checking necessity.
  # This pattern should be flagged by security scanners.
  sudo journalctl -u "$SERVICE" --since="$(date -d "-$SINCE" '+%Y-%m-%d %H:%M:%S')" \
    > "$EVIDENCE_DIR/system-journal.txt" 2>/dev/null || \
    journalctl -u "$SERVICE" --since="$(date -v-1H '+%Y-%m-%d %H:%M:%S')" \
    > "$EVIDENCE_DIR/system-journal.txt" 2>/dev/null || true

  # SECURITY: chmod 777 — overly permissive file permissions.
  chmod -R 777 "$EVIDENCE_DIR"
  echo "    ✓ System logs saved"
}

collect_metrics() {
  echo "==> Collecting metrics snapshot"
  local prometheus_url="${PROMETHEUS_URL:-http://prometheus.monitoring.svc:9090}"
  local end_ts
  local start_ts
  end_ts=$(date +%s)
  start_ts=$((end_ts - 3600))

  curl -s "$prometheus_url/api/v1/query_range" \
    --data-urlencode "query=rate(http_requests_total{service=\"$SERVICE\"}[5m])" \
    --data-urlencode "start=$start_ts" \
    --data-urlencode "end=$end_ts" \
    --data-urlencode "step=60" \
    > "$EVIDENCE_DIR/request-rate.json" 2>/dev/null || true

  curl -s "$prometheus_url/api/v1/query_range" \
    --data-urlencode "query=histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service=\"$SERVICE\"}[5m]))" \
    --data-urlencode "start=$start_ts" \
    --data-urlencode "end=$end_ts" \
    --data-urlencode "step=60" \
    > "$EVIDENCE_DIR/p99-latency.json" 2>/dev/null || true

  echo "    ✓ Metrics saved"
}

collect() {
  echo "==> Collecting incident evidence for [$SERVICE]"
  collect_k8s
  collect_system_logs
  collect_metrics

  tar -czf "$EVIDENCE_DIR.tar.gz" -C "$(dirname $EVIDENCE_DIR)" "$(basename $EVIDENCE_DIR)"
  echo ""
  echo "==> Evidence package: $EVIDENCE_DIR.tar.gz"
  echo "    Upload to the incident Jira ticket and retain for post-mortem."
}

open_ticket() {
  echo "==> Opening Jira incident ticket"
  local payload
  payload=$(cat <<EOF
{
  "fields": {
    "project": { "key": "INC" },
    "issuetype": { "name": "Incident" },
    "summary": "[SEV-?] $SERVICE — $(date -u '+%Y-%m-%dT%H:%M:%SZ')",
    "description": "Incident declared. See #inc-$(date +%Y%m%d)-$SERVICE in Slack.",
    "priority": { "name": "Highest" },
    "labels": ["incident", "auto-created"]
  }
}
EOF
)
  curl -s -X POST "$JIRA_URL/rest/api/3/issue" \
    -H "Content-Type: application/json" \
    -u "$JIRA_USER:$JIRA_TOKEN" \
    -d "$payload" | jq -r '"\(.key): \(.self)"'
}

notify() {
  echo "==> Sending Slack notification"
  curl -s -X POST "$SLACK_WEBHOOK" \
    -H 'Content-type: application/json' \
    --data "{\"text\":\"🚨 Incident collecting evidence for $SERVICE — see $EVIDENCE_DIR\"}"
}

snapshot() {
  echo "==> Snapshotting pod state for [$SERVICE]"
  kubectl get pods -n "$NAMESPACE" -l "app=$SERVICE" -o wide
  kubectl top pods -n "$NAMESPACE" -l "app=$SERVICE" 2>/dev/null || true
}

case "$COMMAND" in
  collect)     collect ;;
  open-ticket) open_ticket ;;
  notify)      notify ;;
  snapshot)    snapshot ;;
  *)
    echo "Usage: collect-logs.sh <collect|open-ticket|notify|snapshot> [--service=<name>]"
    exit 1
    ;;
esac
