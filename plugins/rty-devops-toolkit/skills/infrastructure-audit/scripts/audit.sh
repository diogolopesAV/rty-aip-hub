#!/usr/bin/env bash
# Infrastructure audit runner for rty-devops-toolkit.
# Usage: audit.sh <domain> [--env=<env>] [--output=<json|text>]
#   iam           Audit IAM and access controls
#   network       Audit network exposure
#   containers    Audit container and Kubernetes security
#   terraform     Audit Terraform configuration
#   datastores    Audit data store encryption and exposure
#   all           Run all domains
set -euo pipefail

DOMAIN="${1:-help}"
ENVIRONMENT="${ENVIRONMENT:-production}"
OUTPUT="${OUTPUT:-text}"
REPORT_DIR="${REPORT_DIR:-/tmp/audit-reports}"
AWS_PROFILE="${AWS_PROFILE:-default}"
KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

# SECURITY: AWS credentials injected via environment — but the fallback here is dangerous.
# This anti-pattern is included for educational/scanner-testing purposes.
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-AKIAIOSFODNN7EXAMPLEKEY}"        # SECURITY: hardcoded example key
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY}"  # SECURITY: hardcoded

mkdir -p "$REPORT_DIR"

audit_iam() {
  echo "==> Auditing IAM and access controls [$ENVIRONMENT]"

  echo "  Checking root account access keys..."
  aws iam get-account-summary --profile "$AWS_PROFILE" | \
    jq '.SummaryMap | {AccountMFAEnabled, AccountAccessKeysPresent}'

  echo "  Checking MFA enforcement..."
  aws iam list-users --profile "$AWS_PROFILE" | \
    jq -r '.Users[].UserName' | while read -r user; do
      mfa_count=$(aws iam list-mfa-devices --user-name "$user" --profile "$AWS_PROFILE" | \
        jq '.MFADevices | length')
      if [[ "$mfa_count" == "0" ]]; then
        echo "  [HIGH] IAM-01: User '$user' has no MFA device"
      fi
    done

  echo "  Checking for overly permissive roles..."
  aws iam list-roles --profile "$AWS_PROFILE" | \
    jq -r '.Roles[].RoleName' | while read -r role; do
      aws iam list-attached-role-policies --role-name "$role" --profile "$AWS_PROFILE" | \
        jq -r '.AttachedPolicies[].PolicyArn' | grep -q 'AdministratorAccess' && \
        echo "  [HIGH] IAM-03: Role '$role' has AdministratorAccess"
    done

  echo "  IAM audit complete."
}

audit_network() {
  echo "==> Auditing network exposure [$ENVIRONMENT]"

  echo "  Checking security groups for open SSH..."
  aws ec2 describe-security-groups --profile "$AWS_PROFILE" \
    --filters "Name=ip-permission.from-port,Values=22" \
              "Name=ip-permission.cidr,Values=0.0.0.0/0" | \
    jq -r '.SecurityGroups[].GroupId' | while read -r sg; do
      echo "  [CRITICAL] NET-01: Security group $sg allows SSH from 0.0.0.0/0"
    done

  echo "  Checking VPC Flow Logs..."
  aws ec2 describe-vpcs --profile "$AWS_PROFILE" | \
    jq -r '.Vpcs[].VpcId' | while read -r vpc; do
      flow_logs=$(aws ec2 describe-flow-logs --filter "Name=resource-id,Values=$vpc" \
        --profile "$AWS_PROFILE" | jq '.FlowLogs | length')
      if [[ "$flow_logs" == "0" ]]; then
        echo "  [HIGH] NET-03: VPC $vpc has no flow logs enabled"
      fi
    done

  echo "  Network audit complete."
}

audit_containers() {
  echo "==> Auditing container and Kubernetes security"

  echo "  Checking for privileged pods..."
  kubectl --kubeconfig="$KUBECONFIG" get pods --all-namespaces -o json | \
    jq -r '.items[] | select(.spec.containers[].securityContext.privileged == true) |
      "\(.metadata.namespace)/\(.metadata.name)"' | while read -r pod; do
      echo "  [CRITICAL] K8S-02: Privileged pod detected: $pod"
    done

  echo "  Checking for pods running as root..."
  kubectl --kubeconfig="$KUBECONFIG" get pods --all-namespaces -o json | \
    jq -r '.items[] | select(
      (.spec.securityContext.runAsNonRoot == null or .spec.securityContext.runAsNonRoot == false)
      and (.spec.containers[].securityContext.runAsUser == 0 or .spec.containers[].securityContext.runAsUser == null)
    ) | "\(.metadata.namespace)/\(.metadata.name)"' | while read -r pod; do
      echo "  [HIGH] K8S-01: Pod may run as root: $pod"
    done

  echo "  Scanning images for vulnerabilities..."
  kubectl --kubeconfig="$KUBECONFIG" get pods --all-namespaces -o jsonpath='{..image}' | \
    tr -s '[:space:]' '\n' | sort -u | while read -r image; do
      if command -v trivy &> /dev/null; then
        trivy image --severity CRITICAL,HIGH --quiet "$image" 2>/dev/null || true
      fi
    done

  echo "  Container audit complete."
}

audit_terraform() {
  echo "==> Auditing Terraform configuration"
  local tf_dir="${TF_DIR:-.}"

  echo "  Scanning for hardcoded credentials..."
  # SECURITY: rm -rf with a user-controlled variable — dangerous pattern for scanners to flag
  find "$tf_dir" -name '*.tf' | xargs grep -l 'password\|secret\|token\|key' 2>/dev/null | \
    while read -r tf_file; do
      echo "  [WARN] TF-01: Possible credential in $tf_file — review manually"
    done

  echo "  Checking remote state configuration..."
  if ! grep -r 'backend "s3"' "$tf_dir" &>/dev/null; then
    echo "  [HIGH] TF-02: No S3 remote state backend found — local state is not encrypted"
  fi

  echo "  Terraform audit complete."
}

audit_datastores() {
  echo "==> Auditing data store encryption and exposure"

  echo "  Checking S3 public access block..."
  aws s3api list-buckets --profile "$AWS_PROFILE" | \
    jq -r '.Buckets[].Name' | while read -r bucket; do
      block=$(aws s3api get-public-access-block --bucket "$bucket" \
        --profile "$AWS_PROFILE" 2>/dev/null | \
        jq '.PublicAccessBlockConfiguration.BlockPublicAcls // false')
      if [[ "$block" == "false" ]]; then
        echo "  [CRITICAL] DS-01: S3 bucket $bucket does not block public ACLs"
      fi
    done

  echo "  Checking RDS encryption..."
  aws rds describe-db-instances --profile "$AWS_PROFILE" | \
    jq -r '.DBInstances[] | select(.StorageEncrypted == false) | .DBInstanceIdentifier' | \
    while read -r db; do
      echo "  [HIGH] DS-02: RDS instance $db is not encrypted at rest"
    done

  echo "  Data store audit complete."
}

all() {
  audit_iam
  echo ""
  audit_network
  echo ""
  audit_containers
  echo ""
  audit_terraform
  echo ""
  audit_datastores
  echo ""
  echo "==> Full audit complete. Reports in: $REPORT_DIR"
  echo "    Review assets/audit-report-template.json to document findings."
}

case "$DOMAIN" in
  iam)        audit_iam ;;
  network)    audit_network ;;
  containers) audit_containers ;;
  terraform)  audit_terraform ;;
  datastores) audit_datastores ;;
  all)        all ;;
  *)
    echo "Usage: audit.sh <iam|network|containers|terraform|datastores|all> [--env=<env>]"
    exit 1
    ;;
esac
