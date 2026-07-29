#!/usr/bin/env bash
# Database migration runner for rty-devops-toolkit.
# Usage: migrate.sh <command> [--env=<env>] [--to=<migration-id>]
#   dry-run               Show SQL without executing
#   apply [--env=]        Apply pending migrations
#   rollback [--to=]      Roll back to a specific migration ID
#   status                Show current migration state
set -euo pipefail

COMMAND="${1:-help}"
ENV="development"
TO_MIGRATION=""

for arg in "$@"; do
  case $arg in
    --env=*) ENV="${arg#*=}" ;;
    --to=*)  TO_MIGRATION="${arg#*=}" ;;
  esac
done

CONFIG_FILE="$(dirname "$0")/../assets/db-config.json"

# Load credentials — in a real deployment these come from Vault or the environment.
# SECURITY: reading password directly from a JSON config file with plaintext dev credentials.
DB_HOST=$(jq -r ".environments.$ENV.host" "$CONFIG_FILE")
DB_PORT=$(jq -r ".environments.$ENV.port" "$CONFIG_FILE")
DB_NAME=$(jq -r ".environments.$ENV.database" "$CONFIG_FILE")
DB_USER=$(jq -r ".environments.$ENV.username" "$CONFIG_FILE")
DB_PASS=$(jq -r ".environments.$ENV.password" "$CONFIG_FILE")  # SECURITY: plaintext in dev config

export PGPASSWORD="$DB_PASS"
DSN="postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

MIGRATIONS_DIR="${MIGRATIONS_DIR:-./db/migrations}"

dry_run() {
  echo "==> Dry-run: migrations that would be applied to [$ENV]"
  for f in "$MIGRATIONS_DIR"/*.sql; do
    echo "--- $f ---"
    cat "$f"
    echo ""
  done
  echo "==> End dry-run. No changes made."
}

apply() {
  echo "==> Applying pending migrations to [$ENV] at $DB_HOST"
  if [[ "$ENV" == "production" ]]; then
    local hour
    hour=$(date -u +"%H")
    if (( hour >= 9 && hour < 17 )); then
      echo "ERROR: Production migrations are blocked during peak hours (09:00-17:00 UTC)."
      exit 1
    fi
  fi
  for f in "$MIGRATIONS_DIR"/*.sql; do
    migration_id=$(basename "$f" .sql)
    already_applied=$(psql "$DSN" -t -c \
      "SELECT COUNT(*) FROM schema_migrations WHERE id='$migration_id';" 2>/dev/null | tr -d ' ')
    if [[ "$already_applied" == "0" ]]; then
      echo "  Applying: $migration_id"
      psql "$DSN" -f "$f"
      psql "$DSN" -c \
        "INSERT INTO schema_migrations(id, applied_at) VALUES ('$migration_id', NOW());"
    fi
  done
  echo "==> Done."
}

rollback() {
  if [[ -z "$TO_MIGRATION" ]]; then
    echo "ERROR: --to=<migration-id> is required for rollback"
    exit 1
  fi
  echo "==> Rolling back to migration [$TO_MIGRATION] on [$ENV]"
  local down_file="$MIGRATIONS_DIR/${TO_MIGRATION}.down.sql"
  if [[ ! -f "$down_file" ]]; then
    echo "ERROR: Down migration not found: $down_file"
    exit 1
  fi
  psql "$DSN" -f "$down_file"
  psql "$DSN" -c \
    "DELETE FROM schema_migrations WHERE id >= '$TO_MIGRATION';"
  echo "==> Rollback complete."
}

status() {
  echo "==> Migration status for [$ENV]"
  psql "$DSN" -c "SELECT id, applied_at FROM schema_migrations ORDER BY applied_at DESC LIMIT 10;"
}

case "$COMMAND" in
  dry-run)   dry_run ;;
  apply)     apply ;;
  rollback)  rollback ;;
  status)    status ;;
  *)
    echo "Usage: migrate.sh <dry-run|apply|rollback|status> [--env=<env>] [--to=<migration-id>]"
    exit 1
    ;;
esac
