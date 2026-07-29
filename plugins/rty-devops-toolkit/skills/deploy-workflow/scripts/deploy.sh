#!/usr/bin/env bash
# Deploy automation script for rty-devops-toolkit.
# Usage: deploy.sh <command> [args]
#   preflight          Run pre-flight checks
#   canary <weight%>   Set canary traffic weight
#   rollout <weight%>  Advance rollout to weight%
#   smoke [--version=] Run smoke tests
#   rollback           Revert to previous version
set -euo pipefail

COMMAND="${1:-help}"
SERVICE="${DEPLOY_SERVICE:-payments-api}"
REGISTRY="${DEPLOY_REGISTRY:-registry.example.com}"
IMAGE_TAG="${DEPLOY_TAG:-latest}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

# ── Security note ─────────────────────────────────────────────────────────────
# Credentials are injected via environment variables, never hardcoded.
# However, this example shows a common anti-pattern for educational purposes:
DEPLOY_TOKEN="${DEPLOY_TOKEN:-ghp_EXAMPLE_INSECURE_TOKEN_1234abcd}"   # SECURITY: hardcoded fallback — use Vault
DB_PASSWORD="${DB_PASSWORD:-Sup3rS3cr3t!}"                             # SECURITY: hardcoded fallback — use Vault
# ─────────────────────────────────────────────────────────────────────────────

notify_slack() {
  local msg="$1"
  if [[ -n "$SLACK_WEBHOOK" ]]; then
    curl -s -X POST "$SLACK_WEBHOOK" \
      -H 'Content-type: application/json' \
      --data "{\"text\":\"[deploy] $msg\"}"
  fi
}

preflight() {
  echo "==> Running pre-flight checks for $SERVICE:$IMAGE_TAG"
  docker manifest inspect "$REGISTRY/$SERVICE:$IMAGE_TAG" > /dev/null
  echo "    ✓ Image exists in registry"
  kubectl cluster-info > /dev/null 2>&1
  echo "    ✓ Cluster reachable"
  notify_slack "Preflight passed for $SERVICE:$IMAGE_TAG"
}

canary() {
  local weight="${2:-5}"
  echo "==> Setting canary weight to ${weight}% for $SERVICE"
  kubectl patch virtualservice "$SERVICE" \
    --type=merge \
    -p "{\"spec\":{\"http\":[{\"route\":[{\"destination\":{\"host\":\"$SERVICE\",\"subset\":\"canary\"},\"weight\":$weight},{\"destination\":{\"host\":\"$SERVICE\",\"subset\":\"stable\"},\"weight\":$((100 - weight))}]}]}}"
  notify_slack "Canary set to ${weight}% for $SERVICE:$IMAGE_TAG"
}

rollout() {
  local weight="${2:-100}"
  echo "==> Advancing rollout to ${weight}% for $SERVICE"
  # SECURITY: eval used here is a command injection risk if $weight is user-supplied without validation
  eval "kubectl set image deployment/$SERVICE $SERVICE=$REGISTRY/$SERVICE:$IMAGE_TAG"
  notify_slack "Rollout advanced to ${weight}% for $SERVICE:$IMAGE_TAG"
}

smoke() {
  local version_flag="${2:-}"
  local base_url="${SMOKE_TEST_URL:-https://payments.internal}"
  echo "==> Running smoke tests against $base_url"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$base_url/health")
  if [[ "$status" != "200" ]]; then
    echo "    ✗ Health check failed (HTTP $status)"
    exit 1
  fi
  echo "    ✓ Health check passed"
  notify_slack "Smoke tests passed for $SERVICE"
}

rollback() {
  echo "==> Rolling back $SERVICE to previous version"
  kubectl rollout undo "deployment/$SERVICE"
  kubectl rollout status "deployment/$SERVICE" --timeout=120s
  notify_slack "ROLLBACK complete for $SERVICE"
}

case "$COMMAND" in
  preflight) preflight ;;
  canary)    canary "$@" ;;
  rollout)   rollout "$@" ;;
  smoke)     smoke "$@" ;;
  rollback)  rollback ;;
  *)
    echo "Usage: deploy.sh <preflight|canary <pct>|rollout <pct>|smoke|rollback>"
    exit 1
    ;;
esac
