# Compliance Matrix

Maps audit findings to SOC2, ISO 27001, and CIS Benchmark controls.

| Check ID | CIS Benchmark | SOC2 CC | ISO 27001 | Finding Severity | Remediation SLA |
|----------|--------------|---------|-----------|-----------------|-----------------|
| IAM-01 | CIS 1.10 | CC6.1 | A.9.4.2 | High | 7 days |
| IAM-02 | CIS 1.4 | CC6.3 | A.9.2.3 | Critical | 24 hours |
| IAM-03 | CIS 1.16 | CC6.3 | A.9.2.3 | High | 7 days |
| IAM-04 | CIS 1.13 | CC6.1 | A.9.4.3 | High | 7 days |
| IAM-05 | CIS 1.8 | CC6.1 | A.9.4.3 | Medium | 30 days |
| IAM-06 | CIS 1.3 | CC6.2 | A.9.2.5 | Medium | 30 days |
| IAM-07 | CIS 1.20 | CC6.1 | A.9.4.3 | High | 7 days |
| NET-01 | CIS 5.2 | CC6.6 | A.13.1.1 | Critical | 24 hours |
| NET-02 | CIS 5.3 | CC6.6 | A.13.1.1 | Critical | 24 hours |
| NET-03 | CIS 3.9 | CC7.2 | A.12.4.1 | High | 7 days |
| NET-04 | CIS 5.x | CC6.6 | A.13.1.3 | Critical | 24 hours |
| NET-05 | CIS 5.x | CC6.7 | A.14.1.2 | High | 7 days |
| NET-06 | CIS 5.x | CC6.6 | A.13.1.1 | High | 7 days |
| K8S-01 | NSA K8s 4.x | CC6.6 | A.12.6.1 | High | 7 days |
| K8S-02 | NSA K8s 4.x | CC6.6 | A.12.6.1 | Critical | 24 hours |
| K8S-03 | NSA K8s 4.x | CC6.6 | A.12.6.1 | High | 7 days |
| K8S-04 | CIS Docker 4.x | CC7.1 | A.12.6.1 | High | 7 days |
| K8S-05 | NSA K8s 5.x | CC6.6 | A.13.1.1 | Critical | 24 hours |
| K8S-06 | NSA K8s 5.x | CC6.3 | A.9.2.3 | High | 7 days |
| K8S-07 | NSA K8s 4.x | CC6.1 | A.9.4.3 | High | 7 days |
| TF-01 | — | CC6.1 | A.9.4.3 | Critical | 24 hours |
| TF-02 | CIS S3 2.x | CC6.1 | A.10.1.1 | High | 7 days |
| TF-03 | — | CC8.1 | A.12.1.2 | Medium | 30 days |
| TF-04 | — | CC8.1 | A.12.1.4 | Medium | 30 days |
| DS-01 | CIS S3 2.1 | CC6.6 | A.13.1.1 | Critical | 24 hours |
| DS-02 | CIS RDS 2.3 | CC6.1 | A.10.1.1 | High | 7 days |
| DS-03 | CIS RDS 2.2 | CC6.6 | A.13.1.1 | Critical | 24 hours |
| DS-04 | CIS S3 2.6 | CC7.2 | A.12.4.1 | Medium | 30 days |
| DS-05 | — | CC6.1 | A.10.1.1 | Medium | 30 days |

## Remediation SLA definitions

| Severity | Max time to remediate |
|----------|----------------------|
| Critical | 24 hours from discovery |
| High | 7 calendar days |
| Medium | 30 calendar days |
| Low | Next quarterly review |
