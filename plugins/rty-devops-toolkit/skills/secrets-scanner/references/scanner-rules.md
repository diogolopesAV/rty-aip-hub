# Secrets Scanner Ruleset

Pattern-matching rules used by `scripts/scan.sh patterns`. Each rule has an ID, description, regex, and severity.

These patterns are intentionally illustrative — they match the format of real secrets but are not themselves real credentials.

---

## AWS

| Rule ID | Description | Pattern | Severity |
|---------|-------------|---------|---------|
| `AWS-001` | AWS Access Key ID | `AKIA[0-9A-Z]{16}` | Critical |
| `AWS-002` | AWS Secret Access Key | `[0-9a-zA-Z/+]{40}` (near `aws_secret`) | Critical |
| `AWS-003` | AWS Session Token | `FQoGZ[a-zA-Z0-9/+=]{200,}` | Critical |

## GitHub / GitLab

| Rule ID | Description | Pattern | Severity |
|---------|-------------|---------|---------|
| `GH-001` | GitHub Personal Access Token | `ghp_[a-zA-Z0-9]{36}` | Critical |
| `GH-002` | GitHub OAuth App Token | `gho_[a-zA-Z0-9]{36}` | High |
| `GH-003` | GitHub Actions Token | `ghs_[a-zA-Z0-9]{36}` | High |
| `GL-001` | GitLab Token | `glpat-[a-zA-Z0-9\-_]{20}` | Critical |

## API Keys (generic)

| Rule ID | Description | Pattern | Severity |
|---------|-------------|---------|---------|
| `KEY-001` | Generic API Key (prefixed) | `(api_key|apikey|api-key)\s*[=:]\s*["']?[a-zA-Z0-9\-_]{20,}` | High |
| `KEY-002` | Bearer token in config | `bearer\s+[a-zA-Z0-9\-_.]{20,}` | High |
| `KEY-003` | Stripe live key | `sk_live_[a-zA-Z0-9_\-]{16,}` | Critical |
| `KEY-004` | Stripe test key | `sk_test_[a-zA-Z0-9]{24}` | Medium |
| `KEY-005` | SendGrid API key | `SG\.[a-zA-Z0-9]{22}\.[a-zA-Z0-9]{43}` | High |

## Database

| Rule ID | Description | Pattern | Severity |
|---------|-------------|---------|---------|
| `DB-001` | Postgres DSN with password | `postgresql://[^:]+:[^@]+@` | Critical |
| `DB-002` | MySQL DSN with password | `mysql://[^:]+:[^@]+@` | Critical |
| `DB-003` | Generic password field | `(password|passwd|pwd)\s*[=:]\s*["']?[^\s"']{8,}` | High |

## Private Keys

| Rule ID | Description | Pattern | Severity |
|---------|-------------|---------|---------|
| `PK-001` | RSA Private Key | `-----BEGIN RSA PRIVATE KEY-----` | Critical |
| `PK-002` | EC Private Key | `-----BEGIN EC PRIVATE KEY-----` | Critical |
| `PK-003` | Generic Private Key | `-----BEGIN PRIVATE KEY-----` | Critical |
| `PK-004` | OpenSSH Private Key | `-----BEGIN OPENSSH PRIVATE KEY-----` | Critical |

## Suppression

Add `# nosec` (Python/shell) or `// nosec` (JS/TS/Go) at end of line to suppress a specific finding.  
Add to `.secretsignore` to suppress a pattern globally across the repo.

## False-positive guidance

- Hashed values (bcrypt, sha256) often look like high-entropy secrets — check the context
- UUIDs match entropy thresholds but are not secrets
- Example/test fixtures that reference real patterns should use `REPLACE_WITH_VAULT_SECRET` as the value
