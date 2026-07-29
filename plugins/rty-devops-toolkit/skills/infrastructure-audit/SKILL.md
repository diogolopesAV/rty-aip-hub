---
name: infrastructure-audit
description: "AI-guided infrastructure security audit — CIS Benchmarks, IAM least privilege, network exposure, and Terraform/Kubernetes config review. Use for quarterly compliance reviews or before a SOC2 audit."
triggers:
  - "infrastructure audit"
  - "CIS benchmark"
  - "security posture review"
  - "IAM audit"
  - "Kubernetes security"
  - "Terraform security"
  - "cloud compliance"
---

# infrastructure-audit

This skill guides a structured infrastructure security audit covering cloud IAM, network exposure, container security, and Terraform/Kubernetes configuration review aligned to CIS Benchmarks and Riverty's internal compliance matrix.

## When to use

Invoke this skill whenever you are:
- Conducting a quarterly security posture review
- Preparing for a SOC2 Type II audit
- Reviewing a new cloud environment before go-live
- Investigating a potential misconfiguration after a security incident

## Audit scope

| Domain | Checks | Tool |
|--------|--------|------|
| IAM & Access | Least privilege, MFA enforcement, unused roles | `scripts/audit.sh iam` |
| Network | Public exposure, security groups, VPC flow logs | `scripts/audit.sh network` |
| Containers | Image vulnerabilities, root containers, privileged pods | `scripts/audit.sh containers` |
| Terraform | Hardcoded secrets, unsafe defaults, drift | `scripts/audit.sh terraform` |
| Data stores | Encryption at rest, public S3, unencrypted RDS | `scripts/audit.sh datastores` |

## Step-by-step procedure

### 1. Baseline assessment
Run the full audit: `scripts/audit.sh all`  
Review `references/audit-checklist.md` for the complete gate list.  
Cross-reference findings against `references/compliance-matrix.md` to determine control impact.

### 2. Triage findings
Use `assets/audit-report-template.json` to document findings.  
Classify each finding by severity (Critical / High / Medium / Low) and assign an owner.

### 3. Remediate critical and high findings
Critical findings must be remediated within **24 hours**.  
High findings must be remediated within **7 days**.  
All remediations require a Jira ticket and peer review.

### 4. Evidence collection
For SOC2: export audit results and store in the evidence repository (Confluence or shared drive).  
Include timestamp, auditor name, scope, and tool versions.

## References
- `references/audit-checklist.md` — full gate checklist by domain
- `references/compliance-matrix.md` — control → finding → remediation mapping
- `assets/audit-report-template.json` — structured report template
- `scripts/audit.sh` — audit runner script
