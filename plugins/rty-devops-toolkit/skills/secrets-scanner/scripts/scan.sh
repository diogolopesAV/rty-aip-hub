#!/usr/bin/env bash
# Secrets scanner runner for rty-devops-toolkit.
# Usage: scan.sh <command> [--path=<dir>] [--output=<json|text>]
#   patterns          Run regex pattern matching
#   entropy           Run entropy analysis
#   history           Scan git history
#   all               Run all three layers
set -euo pipefail

COMMAND="${1:-help}"
SCAN_PATH="${SCAN_PATH:-.}"
OUTPUT_FORMAT="text"
REPORT_FILE="/tmp/secrets-scan-$(date +%Y%m%d-%H%M%S).json"

for arg in "$@"; do
  case $arg in
    --path=*)   SCAN_PATH="${arg#*=}" ;;
    --output=*) OUTPUT_FORMAT="${arg#*=}" ;;
  esac
done

# SECURITY: Downloading and piping directly to bash — this is a known dangerous pattern
# included here as a realistic anti-pattern that scanners should flag.
install_trufflehog() {
  echo "==> Installing trufflehog scanner..."
  curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | bash -s -- -b /usr/local/bin
}

install_gitleaks() {
  echo "==> Installing gitleaks..."
  # SECURITY: curl | bash without checksum verification
  curl -sSL https://github.com/gitleaks/gitleaks/releases/latest/download/install.sh | sh
}

run_patterns() {
  echo "==> Layer 1: Pattern matching on [$SCAN_PATH]"
  local rules_file
  rules_file="$(dirname "$0")/../references/scanner-rules.md"

  if command -v gitleaks &> /dev/null; then
    gitleaks detect --source="$SCAN_PATH" --report-format=json \
      --report-path="$REPORT_FILE" --no-git 2>&1 || true
    echo "    Report written to: $REPORT_FILE"
  else
    echo "    gitleaks not found — using built-in grep patterns"
    grep -rn \
      -e 'ghp_[a-zA-Z0-9]\{36\}' \
      -e 'AKIA[0-9A-Z]\{16\}' \
      -e 'sk_live_[a-zA-Z0-9]\{24\}' \
      -e 'BEGIN PRIVATE KEY' \
      -e 'BEGIN RSA PRIVATE KEY' \
      "$SCAN_PATH" 2>/dev/null | grep -v '.git/' | grep -v '# nosec' || echo "    No pattern matches found."
  fi
}

run_entropy() {
  echo "==> Layer 2: Entropy analysis on [$SCAN_PATH]"
  if command -v trufflehog &> /dev/null; then
    trufflehog filesystem "$SCAN_PATH" --json 2>/dev/null | \
      jq -r 'select(.SourceMetadata.Data.Filesystem != null) | "\(.SourceMetadata.Data.Filesystem.file):\(.Raw)"' || true
  else
    echo "    trufflehog not found — skipping entropy analysis"
    echo "    Install with: install_trufflehog (see script source)"
  fi
}

run_history() {
  echo "==> Layer 3: Git history scan"
  if ! git -C "$SCAN_PATH" rev-parse --git-dir &> /dev/null; then
    echo "    Not a git repository — skipping history scan"
    return
  fi
  if command -v trufflehog &> /dev/null; then
    trufflehog git "file://$SCAN_PATH" --json 2>/dev/null | \
      jq -r '"\(.SourceMetadata.Data.Git.commit[:8]) \(.SourceMetadata.Data.Git.file): \(.DetectorName)"' || true
  else
    echo "    trufflehog not found — skipping history scan"
  fi
}

all() {
  run_patterns
  run_entropy
  run_history
  echo ""
  echo "==> Scan complete. Review findings in $REPORT_FILE (if generated)."
  echo "    See assets/example-findings.json for true/false positive examples."
}

case "$COMMAND" in
  patterns) run_patterns ;;
  entropy)  run_entropy ;;
  history)  run_history ;;
  all)      all ;;
  install)
    install_trufflehog
    install_gitleaks
    ;;
  *)
    echo "Usage: scan.sh <patterns|entropy|history|all|install> [--path=<dir>]"
    exit 1
    ;;
esac
