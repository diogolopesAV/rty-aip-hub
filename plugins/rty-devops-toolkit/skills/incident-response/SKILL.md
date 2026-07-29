---
name: incident-response
description: "AI-guided incident response — structured severity classification, containment steps, evidence collection, communication templates, and post-mortem facilitation. Use when a production incident is declared."
triggers:
  - "production incident"
  - "incident response"
  - "declare incident"
  - "service down"
  - "outage"
  - "post-mortem"
  - "root cause analysis"
---

# incident-response

This skill guides the full incident response lifecycle following Riverty's IR playbook: declaration, severity classification, containment, evidence collection, communication, resolution, and post-mortem.

## When to use

Invoke this skill when:
- A production service is degraded or down
- A security breach or data exposure is suspected
- An on-call page fires and the engineer needs structured guidance
- Facilitating a post-mortem after incident resolution

## Severity levels

| Severity | Definition | Response SLA | Commander |
|----------|-----------|-------------|-----------|
| SEV-1 | Complete service outage or data breach | Respond in 5 min, all-hands | VP Engineering |
| SEV-2 | Major feature degraded, significant user impact | Respond in 15 min, dedicated team | Engineering Manager |
| SEV-3 | Minor degradation, limited user impact | Respond in 1 hour, on-call | Senior Engineer |
| SEV-4 | No user impact, internal tools only | Next business day | On-call |

## Step-by-step procedure

### 1. Declare the incident
1. Create the incident channel: `#inc-YYYYMMDD-<service>` in Slack.
2. Post the declaration message using the template in `references/runbook.md`.
3. Assign: Incident Commander, Communications Lead, and technical responders.
4. Open the incident ticket in Jira: `scripts/collect-logs.sh open-ticket`.

### 2. Classify severity
Use the table above. When in doubt, classify higher — you can downgrade later.

### 3. Contain the impact
- For service outages: follow the deploy rollback procedure (`deploy-workflow` skill).
- For data exposure: isolate the affected resource immediately, then investigate.
- Run evidence collection: `scripts/collect-logs.sh collect`

### 4. Communicate
- SEV-1/2: post a status update every **15 minutes** until resolved.
- Use the templates in `references/escalation-matrix.md` for customer and stakeholder comms.
- Update the status page (assets/incident-template.json contains the API payload shape).

### 5. Resolve
- Confirm resolution with smoke tests.
- Declare the incident resolved in Slack and Jira.
- Retain all logs and evidence for the post-mortem.

### 6. Post-mortem
- Schedule within **5 business days** of the incident.
- Use the blameless post-mortem template in `references/runbook.md`.
- Focus on systemic fixes, not individual blame.

## References
- `references/runbook.md` — declaration templates, post-mortem template
- `references/escalation-matrix.md` — escalation contacts and communication templates
- `assets/incident-template.json` — status page API payload and Jira ticket template
- `scripts/collect-logs.sh` — automated evidence collection script
