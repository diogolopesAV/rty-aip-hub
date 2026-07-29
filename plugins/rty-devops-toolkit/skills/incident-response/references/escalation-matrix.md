# Escalation Matrix

## Internal escalation contacts

| Role | SEV-1 | SEV-2 | SEV-3 |
|------|-------|-------|-------|
| On-call Engineer | Immediately | Immediately | Immediately |
| Engineering Manager | Immediately | Within 15 min | Awareness only |
| VP Engineering | Immediately | If > 30 min | Not required |
| CTO | If data breach or > 1 hr SEV-1 | Not required | Not required |
| Legal/Compliance | If data breach | Not required | Not required |

## Customer communication templates

### Initial notification (SEV-1/2 — send within 15 min of declaration)

Subject: `[Riverty] Service Degradation — <Service> — Investigating`

```
We are aware of an issue affecting <service> and are actively investigating.

Impact: <what users are experiencing>
Status: We are investigating the root cause and will provide an update within 30 minutes.

We apologize for the inconvenience.
— Riverty Engineering
```

### Update notification

Subject: `[Riverty] Update: <Service> Incident — <Status>`

```
We are providing an update on the ongoing <service> incident.

Current status: <INVESTIGATING | IDENTIFIED | MONITORING>
Update: <what has been done / what is happening>
Next update: within <N> minutes.
```

### Resolution notification

Subject: `[Riverty] Resolved: <Service> Incident`

```
We are pleased to inform you that the <service> incident has been resolved.

Duration: <HH:MM>
Root cause: <brief explanation>
What we did: <fix applied>
What we are doing next: <preventive measures>

We apologize for the disruption and will share a full post-mortem within 5 business days.
— Riverty Engineering
```

## External escalation

| Vendor | Contact | Use for |
|--------|---------|---------|
| AWS Support | via AWS Console (Business/Enterprise) | Infrastructure outages |
| PagerDuty | pagerduty-support@example.com | On-call platform issues |
| Cloudflare | via Cloudflare Dashboard | DDoS / DNS issues |
