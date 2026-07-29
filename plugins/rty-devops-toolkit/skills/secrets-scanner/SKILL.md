---
name: secrets-scanner
description: "AI-guided secrets scanning — detect hardcoded credentials, API keys, and tokens in source code before they reach production. Use before every commit to main or before a code review."
triggers:
  - "scan for secrets"
  - "check for credentials"
  - "detect API keys"
  - "find hardcoded passwords"
  - "secrets leak"
  - "pre-commit secrets check"
---

# secrets-scanner

This skill guides you through scanning a repository for hardcoded credentials, API keys, tokens, and other sensitive material using Riverty's layered detection approach: pattern matching, entropy analysis, and Git history scanning.

## When to use

Invoke this skill whenever you are:
- About to merge a PR to main
- Reviewing a branch that touched configuration files, `.env` files, or infrastructure code
- Onboarding a new repository to the security pipeline
- Investigating a suspected credential leak

## Detection layers

### Layer 1 — Pattern matching (fast, low false-negative)
Regex patterns for known secret formats. See `references/scanner-rules.md` for the full ruleset.  
Run: `scripts/scan.sh patterns`

### Layer 2 — Entropy analysis (catches custom/generated secrets)
High-entropy strings (> 3.5 Shannon entropy) in source files are flagged for review.  
Run: `scripts/scan.sh entropy`

### Layer 3 — Git history scan (catches secrets that were "deleted")
Scans full commit history including deleted lines.  
Run: `scripts/scan.sh history`

## Step-by-step procedure

1. Run the full scan suite: `scripts/scan.sh all`
2. Review `assets/example-findings.json` to understand what a true positive looks like vs. a false positive.
3. For each finding, classify:
   - **True positive**: rotate the secret immediately, then remove it from the codebase and history (`git filter-repo`)
   - **False positive**: add an inline suppression comment `# nosec` or add the pattern to `.secretsignore`
4. Confirm clean: re-run `scripts/scan.sh all` — expect zero findings before merging.

## Severity levels

| Severity | Examples |
|----------|---------|
| Critical | Live production API keys, database passwords, private keys |
| High | Staging credentials, internal service tokens |
| Medium | Dev credentials, example values that match real patterns |
| Low | High-entropy strings that are likely hashes or UUIDs |

## References
- `references/scanner-rules.md` — regex ruleset for common secret formats
- `assets/example-findings.json` — example true/false positive findings for training
- `scripts/scan.sh` — scanner runner script
