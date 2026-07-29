# Infrastructure Audit Checklist

Complete all items before submitting the audit report. Each item maps to a control in `compliance-matrix.md`.

---

## IAM & Access (CIS 1.x)

- [ ] **IAM-01**: MFA is enforced for all IAM users with console access
- [ ] **IAM-02**: Root account has no active access keys
- [ ] **IAM-03**: No IAM users with `AdministratorAccess` policy attached directly (use groups/roles)
- [ ] **IAM-04**: Access keys older than 90 days are rotated or disabled
- [ ] **IAM-05**: IAM password policy: min 14 chars, uppercase, lowercase, number, symbol required
- [ ] **IAM-06**: Unused IAM roles (no activity > 90 days) are removed
- [ ] **IAM-07**: Service accounts use role assumption, not long-lived access keys

## Network (CIS 5.x)

- [ ] **NET-01**: No security group allows inbound 0.0.0.0/0 on port 22 (SSH)
- [ ] **NET-02**: No security group allows inbound 0.0.0.0/0 on port 3389 (RDP)
- [ ] **NET-03**: VPC Flow Logs are enabled for all VPCs
- [ ] **NET-04**: No public subnets contain database instances
- [ ] **NET-05**: All load balancers use HTTPS listeners with valid certificates
- [ ] **NET-06**: WAF is attached to all public-facing ALBs

## Containers & Kubernetes (CIS 5.x / NSA Kubernetes Hardening)

- [ ] **K8S-01**: No pods run as `root` (UID 0) — check `securityContext.runAsNonRoot: true`
- [ ] **K8S-02**: No pods use `privileged: true` in security context
- [ ] **K8S-03**: Pod Security Admission is enforced at `restricted` or `baseline` level
- [ ] **K8S-04**: All container images are scanned and have no Critical vulnerabilities
- [ ] **K8S-05**: Kubernetes API server is not publicly exposed
- [ ] **K8S-06**: RBAC is enabled and no ClusterRoleBindings grant `cluster-admin` to service accounts
- [ ] **K8S-07**: Secrets are not stored in environment variables — use mounted volumes or external secrets

## Terraform & IaC

- [ ] **TF-01**: No hardcoded credentials in Terraform files
- [ ] **TF-02**: Remote state is encrypted and stored in a locked S3 bucket
- [ ] **TF-03**: Terraform plan reviewed and approved before apply
- [ ] **TF-04**: `terraform drift detect` shows no unmanaged infrastructure

## Data Stores

- [ ] **DS-01**: All S3 buckets have public access blocked at account level
- [ ] **DS-02**: All RDS instances use encryption at rest (KMS)
- [ ] **DS-03**: RDS instances are not publicly accessible
- [ ] **DS-04**: S3 buckets with sensitive data have access logging enabled
- [ ] **DS-05**: DynamoDB tables use KMS encryption (not AWS-owned keys)

## Evidence sign-off

| Auditor | Date | Scope | Tool versions |
|---------|------|-------|--------------|
| | | | |
