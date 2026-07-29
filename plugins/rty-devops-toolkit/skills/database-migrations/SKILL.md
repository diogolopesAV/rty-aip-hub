---
name: database-migrations
description: "AI-guided database migration workflow — authoring safe schema changes, dry-run validation, staged application, and rollback. Use before any deployment that includes schema changes."
triggers:
  - "database migration"
  - "schema change"
  - "ALTER TABLE"
  - "migrate database"
  - "apply migration"
  - "rollback migration"
---

# database-migrations

This skill guides safe, reversible database schema changes following Riverty's zero-downtime migration standards. It covers migration authoring, dry-run validation, staged application across environments, and rollback.

## When to use

Invoke this skill whenever you are:
- Writing a new database migration file
- Applying pending migrations to staging or production
- Evaluating whether a migration is safe to run during a live deploy
- Rolling back a schema change that caused issues

## Zero-downtime migration rules

Always follow these rules to avoid locking production tables:

1. **Add columns as nullable** — never add a NOT NULL column without a default in one step
2. **Backfill in batches** — update existing rows in chunks of 1,000–10,000 with `pg_sleep` between batches
3. **Add constraint after backfill** — apply NOT NULL / FK constraints only after all rows satisfy them
4. **Index concurrently** — use `CREATE INDEX CONCURRENTLY` to avoid table locks
5. **Never rename columns directly** — add new column, backfill, update app, then drop old column across 3 separate deploys

## Step-by-step procedure

### 1. Author the migration
Review `references/migration-patterns.md` for safe patterns for common operations.  
Check `assets/db-config.json` for the target environment connection parameters.

### 2. Dry-run validation
```bash
scripts/migrate.sh dry-run
```
Expected: shows the SQL that would be executed; confirms no table-locking operations.

### 3. Apply to staging
```bash
scripts/migrate.sh apply --env=staging
```
Verify application logs for errors after applying.

### 4. Apply to production (after deploy approval)
```bash
scripts/migrate.sh apply --env=production
```
Never apply production migrations during peak traffic hours (09:00–17:00 UTC).

### 5. Rollback
```bash
scripts/migrate.sh rollback --to=<migration-id>
```
See `references/migration-patterns.md` for the down-migration template.

## References
- `references/migration-patterns.md` — safe patterns for common schema changes
- `assets/db-config.json` — database connection configuration schema
- `scripts/migrate.sh` — migration runner script
