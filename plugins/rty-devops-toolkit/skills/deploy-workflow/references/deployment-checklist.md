# Deployment Pre-flight Checklist

Complete every item before advancing beyond the canary stage. Record your sign-off in the deploy PR comment.

## Code & Build
- [ ] Release branch is merged and all CI checks pass (green)
- [ ] Artifact SHA in registry matches the release tag SHA
- [ ] No `TODO(ship-blocker)` or `FIXME(prod)` comments in the diff
- [ ] Dependency vulnerability scan clean (`npm audit` / `trivy image`)

## Configuration
- [ ] All required environment variables are set in the target environment's secrets manager
- [ ] No credentials or tokens committed to the repository (run `secrets-scanner` skill)
- [ ] Feature flags reviewed — new flags default to `false` in production
- [ ] `assets/deploy-config.json` values match the environment-specific overrides in Vault

## Database
- [ ] All pending migrations applied to staging and verified (see `database-migrations` skill)
- [ ] Migration rollback script tested in staging
- [ ] No long-running locks expected during migration window

## Observability
- [ ] Dashboards open: error rate, p99 latency, throughput, saturation
- [ ] Alerts are active (not silenced) for the target service
- [ ] On-call engineer is aware and monitoring

## Rollback readiness
- [ ] Previous artifact version is still available in the registry
- [ ] Rollback procedure reviewed (`references/rollback-procedures.md`)
- [ ] Database rollback migration ready if schema changed
- [ ] Load-balancer can revert weights within 60 seconds

## Sign-off
| Role | Name | Time (UTC) |
|------|------|------------|
| Engineer | | |
| On-call | | |
| (Optional) Stakeholder | | |
