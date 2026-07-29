# Migration Patterns Reference

Safe patterns for the most common schema change operations. Each pattern is annotated with lock risk and the recommended approach.

---

## Add a nullable column (safe — no lock)

```sql
-- UP
ALTER TABLE orders ADD COLUMN notes TEXT;

-- DOWN
ALTER TABLE orders DROP COLUMN notes;
```
**Lock risk**: none. Always use `TEXT` (or other nullable type) with no default for new columns in large tables.

---

## Add a NOT NULL column with default (multi-step — required for large tables)

**Step 1** (deploy N): add nullable
```sql
ALTER TABLE orders ADD COLUMN status_code VARCHAR(10);
```

**Step 2** (deploy N): backfill in batches
```sql
DO $$
DECLARE
  batch_size INT := 5000;
  offset_val INT := 0;
  rows_updated INT;
BEGIN
  LOOP
    UPDATE orders
    SET status_code = 'PENDING'
    WHERE status_code IS NULL
    LIMIT batch_size;
    GET DIAGNOSTICS rows_updated = ROW_COUNT;
    EXIT WHEN rows_updated = 0;
    PERFORM pg_sleep(0.05);
  END LOOP;
END $$;
```

**Step 3** (deploy N+1): add constraint
```sql
ALTER TABLE orders ALTER COLUMN status_code SET NOT NULL;
ALTER TABLE orders ALTER COLUMN status_code SET DEFAULT 'PENDING';
```

---

## Add an index (non-blocking)

```sql
-- UP (use CONCURRENTLY to avoid table lock)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- DOWN
DROP INDEX CONCURRENTLY IF EXISTS idx_orders_user_id;
```
**Lock risk**: none with CONCURRENTLY. Never use plain `CREATE INDEX` on a large table in production.

---

## Rename a column (multi-deploy — 3 steps)

**Step 1**: add new column and write to both
```sql
ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
```

**Step 2**: backfill + update application to read new column

**Step 3**: drop old column
```sql
ALTER TABLE users DROP COLUMN email;
```

---

## Migration file template

```
-- Migration: <id>_<short_description>
-- Author: <name>
-- Date: <YYYY-MM-DD>
-- Jira: <ticket>

-- UP
BEGIN;

-- your changes here

COMMIT;

-- DOWN
BEGIN;

-- your rollback here

COMMIT;
```
