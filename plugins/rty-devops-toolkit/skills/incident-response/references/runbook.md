# Incident Response Runbook

## Declaration template (paste into #inc-YYYYMMDD-<service>)

```
🚨 INCIDENT DECLARED — <SEV-N>
Service:   <service name>
Impact:    <what users/systems are affected>
Symptoms:  <what is observed — errors, latency, unavailability>
Commander: @<name>
Comms:     @<name>
Bridge:    <Zoom link>
Jira:      <ticket URL>
Status:    INVESTIGATING
```

## Incident update template (post every 15 min for SEV-1/2)

```
⏱ INCIDENT UPDATE — <SEV-N> | <HH:MM UTC>
Status:      INVESTIGATING | IDENTIFIED | MONITORING | RESOLVED
Impact:      <current state>
Last action: <what was just done>
Next step:   <what happens next>
ETA:         <estimated resolution time or UNKNOWN>
```

## Resolution template

```
✅ INCIDENT RESOLVED — <SEV-N>
Duration:   <HH:MM>
Root cause: <one-line summary>
Fix:        <what was done to resolve>
Follow-up:  Post-mortem scheduled for <date>
Jira:       <ticket URL>
```

---

## Blameless post-mortem template

```
# Post-mortem: <Incident Title>
Date:       <YYYY-MM-DD>
Severity:   <SEV-N>
Duration:   <HH:MM>
Facilitator: <name>
Attendees:  <names>

## Summary
<2-3 sentence summary of what happened and the user impact.>

## Timeline (UTC)
| Time | Event |
|------|-------|
| HH:MM | First alert / symptom observed |
| HH:MM | Incident declared |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Incident resolved |

## Root cause
<Technical description of what caused the incident.>

## Contributing factors
- <Factor 1>
- <Factor 2>

## What went well
- <Detection was fast / rollback worked / team communication was clear>

## What could be improved
- <Gap 1>
- <Gap 2>

## Action items
| Action | Owner | Due Date | Jira |
|--------|-------|----------|------|
| | | | |

## Lessons learned
<Key takeaways for the team.>
```
