---
name: deploy-workflow
description: "AI-guided production deployment workflow — pre-flight checks, staged rollout, smoke tests, and rollback procedures. Use when releasing any service to staging or production."
triggers:
  - "deploy to production"
  - "release workflow"
  - "rollout"
  - "blue-green deploy"
  - "canary release"
---

# deploy-workflow

This skill guides you through Riverty's standard production deployment process. It covers pre-flight validation, staged rollout (canary → 25% → 100%), post-deploy smoke tests, and rollback procedures.

## When to use

Invoke this skill whenever you are:
- Cutting a release to staging or production
- Performing a blue-green or canary deployment
- Rolling back a failed release
- Reviewing whether a deploy is safe to proceed

## Prerequisites

- CI pipeline is green on the release branch
- Database migrations reviewed (see `database-migrations` skill)
- On-call engineer notified and available
- Deployment config reviewed — see `assets/deploy-config.json` for the expected shape

## Step-by-step procedure

### 1. Pre-flight checks
1. Confirm the release tag matches the artifact in the registry: `scripts/deploy.sh preflight`
2. Verify feature flags are set correctly for the target environment.
3. Check downstream service SLOs — do not deploy if any dependency is degraded.
4. Review `references/deployment-checklist.md` and tick every item before proceeding.

### 2. Canary rollout (5%)
1. Update the load-balancer weight: `scripts/deploy.sh canary 5`
2. Monitor error rate and p99 latency for **10 minutes** before continuing.
3. If error rate exceeds 1% or p99 degrades > 20%, execute rollback immediately.

### 3. Staged rollout (25% → 100%)
1. Advance to 25%: `scripts/deploy.sh rollout 25`
2. Hold for **5 minutes**, confirm metrics.
3. Advance to 100%: `scripts/deploy.sh rollout 100`

### 4. Smoke tests
Run the post-deploy smoke suite: `scripts/deploy.sh smoke`  
Expected: all checks pass with exit code 0.

### 5. Rollback
If anything fails: `scripts/deploy.sh rollback`  
Full procedure in `references/rollback-procedures.md`.

## References
- `references/deployment-checklist.md` — pre-flight gate checklist
- `references/rollback-procedures.md` — step-by-step rollback runbook
- `assets/deploy-config.json` — deployment configuration schema and example
- `scripts/deploy.sh` — deploy automation script
