# Rollback Procedures

Use this runbook when a deployment must be aborted or reversed. Target resolution time: **< 5 minutes** from decision to rollback complete.

## Decision criteria — when to rollback

Immediately rollback if any of the following are true:
- Error rate on the new version exceeds **1%** (sustained over 2 minutes)
- p99 latency degrades more than **20%** vs. the pre-deploy baseline
- Any critical alert fires that was not firing before the deploy
- On-call engineer judges the risk unacceptable

## Automated rollback (preferred)

```bash
# Revert load-balancer to previous version and drain new pods
scripts/deploy.sh rollback

# Verify: all traffic returning 200 on previous version
scripts/deploy.sh smoke --version=previous
```

The script performs:
1. LB weight shift: 100% to previous version in < 30 s
2. Pod drain + termination of new-version pods
3. Smoke test against previous version endpoint
4. Slack notification to `#deployments` channel

## Manual rollback

If the automated script fails:

```bash
# Step 1: shift traffic back immediately
kubectl set image deployment/<service> \
  <container>=registry.example.com/<service>:<previous-tag>

# Step 2: scale down new version
kubectl scale deployment/<service>-canary --replicas=0

# Step 3: confirm rollout
kubectl rollout status deployment/<service>
```

## Database rollback

If a migration was applied, run the down migration:

```bash
# Identify the last applied migration
psql $DATABASE_URL -c "SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 5;"

# Run the rollback
./bin/migrate down --to=<previous-migration-id>
```

> **Warning**: data-destructive down migrations (DROP COLUMN, DROP TABLE) cannot be reversed automatically. Restore from the pre-deploy snapshot if needed.

## Post-rollback checklist

- [ ] All dashboards return to pre-deploy baseline
- [ ] No alerts firing
- [ ] Incident post-mortem ticket created in Jira
- [ ] Root cause documented before re-attempting deploy
