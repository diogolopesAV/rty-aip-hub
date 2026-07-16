---
name: rty-terraform-azure-cdn-classic-migration
description: Guides the full Azure CDN Classic to Azure Front Door migration for Terraform-managed environments. Use when a Portal migration has already created Azure Front Door resources and Terraform must be rewritten, state-migrated, imported, and reconciled across environments, including Key Vault-backed certificate cases. Do not use for brand-new Front Door deployments, generic Terraform state repair, or non-classic CDN migrations.
---

# Azure CDN Classic → Azure Front Door: Terraform Migration

Two-phase migration process: the Azure Portal handles the data-plane cutover (zero-downtime), then Terraform state is updated to track the already-migrated resources under new HCL.

**Key principle:** After the Portal migration, AFD resources already exist in Azure. Do NOT destroy and recreate. Only rearrange Terraform state and rewrite HCL to match reality.

## When to Use

Use this skill when:
- Migrating `azurerm_cdn_profile` / `azurerm_cdn_endpoint` resources to AFD
- Performing `terraform state rm` + `terraform import` after an Azure Portal CDN migration
- Resolving Terraform plan drift after importing AFD resources
- Applying a migration lock for multi-environment (test → live) rollout

Do not use when:
- Setting up Azure Front Door for the first time (no existing CDN)
- General Terraform state repair unrelated to CDN-to-AFD migration
- Migrating from third-party CDN providers

## Prerequisites

| Requirement | Detail |
|---|---|
| Terraform | >= 1.9 |
| azurerm provider | >= 4.x (v3.x uses different attribute names) |
| Azure CLI | Discovery and import commands |
| State backup | Run `terraform state pull` before any surgery |
| Non-prod env | Always migrate test/dev first |

> Do not run `terraform plan` or `terraform apply` between the Portal migration and completing the Terraform state migration. Terraform will attempt to recreate the deleted CDN resources.

---

## Phase 1 — Portal Migration

This phase has no Terraform involvement.

1. Navigate to the CDN profile in the Azure Portal.
2. Use the **Migrate** button to convert the profile.
3. Select target SKU: `Standard_AzureFrontDoor` or `Premium_AzureFrontDoor`.
4. Azure converts endpoints, rules, and custom domains in-place. DNS continues to work.

**What the Portal migration creates (affects later HCL authoring):**

| What | Convention |
|---|---|
| Endpoint names | May differ from Terraform naming pattern |
| Route names | Auto-generated, alphanumeric, no hyphens |
| Rule set names | Prefixed with `Migrated` (e.g., `MigratedMyEndpoint01`) |
| Origin group names | Suffixed with `-Default` |
| Legacy `*.azureedge.net` domains | Created as `azurerm_cdn_frontdoor_custom_domain` with `-Migrated` suffix |
| Origin groups | Minimal config — no health probes, default load balancing |
| Routes | `MatchRequest` forwarding protocol (not `HttpsOnly`) |

**Live / customer-certificate variant:** some environments have extra Portal steps:

1. Enable a system-assigned managed identity on the new AFD profile.
2. Grant that identity access to the external Key Vault.
3. Let the Portal create the AFD secret resource for the custom domain certificate.

Treat the managed identity state, Key Vault dependency, and AFD secret name as discovered facts. They change the later HCL and import steps.

---

## Phase 2 — Terraform State Migration

### Step 0 — Discovery

Enumerate every AFD resource in Azure. Record exact names and resource IDs for import. You can either run the helper script `assets/migrate-script.sh` from the repo root (it wraps these discovery commands) or execute them manually as shown below.

```bash
RG="your-resource-group"
PROFILE="your-afd-profile-name"

az afd endpoint list      --profile-name $PROFILE -g $RG -o table
az afd origin-group list  --profile-name $PROFILE -g $RG -o table
az afd rule-set list      --profile-name $PROFILE -g $RG -o table
az afd custom-domain list --profile-name $PROFILE -g $RG -o table
az afd secret list        --profile-name $PROFILE -g $RG -o table

# Origins per group
az afd origin list --profile-name $PROFILE -g $RG --origin-group-name <each-group> -o table

# Routes per endpoint
for EP in $(az afd endpoint list --profile-name $PROFILE -g $RG --query "[].name" -o tsv); do
  echo "=== $EP ==="
  az afd route list --profile-name $PROFILE -g $RG --endpoint-name $EP -o table
done

# Rules per rule set (note order numbers — must match exactly)
for RS in $(az afd rule-set list --profile-name $PROFILE -g $RG --query "[].name" -o tsv); do
  echo "=== $RS ==="
  az afd rule list --profile-name $PROFILE -g $RG --rule-set-name $RS -o table
done

az afd profile show --profile-name $PROFILE -g $RG --query "{identity: identity, id: id}" -o json
```

Record: endpoint names, route names, rule-set names, rule orders, custom-domain names, legacy `-Migrated` domain names, secret names, origin hostnames, and whether the profile already has a managed identity.

Do not assume names can be derived from a single interpolation pattern. Portal-generated names may differ across environments.

### Step 1 — Code Changes

Commit all HCL changes before running any state operations. This enables clean `git revert` if needed.

#### 1a. Migration Lock (multi-environment only)

```hcl
variable "allow_frontdoor_migration" {
  type    = bool
  default = false

  validation {
    condition     = var.allow_frontdoor_migration || var.environment != "live"
    error_message = "Front Door migration is locked. Add `allow_frontdoor_migration = true` only after Portal migration and discovery are complete."
  }
}
```

Set `allow_frontdoor_migration = true` only in tfvars for environments that completed the Portal migration.

#### 1b. Delete Classic CDN HCL

Delete (do not comment out) all `azurerm_cdn_profile`, `azurerm_cdn_endpoint`, and `azurerm_cdn_endpoint_custom_domain` resource blocks.

#### 1c. Write AFD Profile HCL

Use the BIP-provided module:

```hcl
module "cdn_frontdoor_profile" {
  source  = "app.terraform.io/afs/cdn_frontdoor_profile/azurerm"
  version = "~> 0.0.2"

  frontdoor_profile_name = "your-afd-profile-name"    # Must match Azure
  resource_group_name    = azurerm_resource_group.main.name
  frontdoor_profile_sku  = "Standard_AzureFrontDoor"
  tags                   = local.tags
}
```

If the environment uses a Key Vault-backed certificate, add a secret resource that matches the Portal-created AFD secret:

```hcl
data "azurerm_key_vault" "external" {
  count               = var.enable_kv_cert ? 1 : 0
  name                = "your-kv-name"
  resource_group_name = "your-kv-rg"
}

data "azurerm_key_vault_certificate" "root_domain" {
  count        = var.enable_kv_cert ? 1 : 0
  name         = "your-cert-name"
  key_vault_id = data.azurerm_key_vault.external[0].id
}

resource "azurerm_cdn_frontdoor_secret" "root_domain_cert" {
  count                    = var.enable_kv_cert ? 1 : 0
  name                     = local.afd_kv_secret_name
  cdn_frontdoor_profile_id = module.cdn_frontdoor_profile.id

  secret {
    customer_certificate {
      key_vault_certificate_id = data.azurerm_key_vault_certificate.root_domain[0].versionless_id
    }
  }
}
```

Rules:

- Use `key_vault_certificate_id`, not `key_vault_secret_id`.
- Use the certificate `versionless_id`, not the versioned `.id`.
- Match the secret `name` to the exact AFD secret name discovered from Azure.

#### 1d. Write AFD Endpoint HCL

Decision: **BIP module vs raw resources.**

- Use `app.terraform.io/afs/cdn_frontdoor_endpoint/azurerm` module for standard endpoints.
- Use raw `azurerm_cdn_frontdoor_*` resources for endpoints needing complex rule logic (CORS, URL rewrites, multi-rule cache policies).
- Both can coexist in the same profile — reference `module.cdn_frontdoor_profile.id` for the shared profile.

Do not assume a single interpolation pattern will reproduce every Portal-generated endpoint, route, or rule-set name across environments. Prefer env-specific maps or variables holding the discovered names.

Read `references/resource-mapping.md` for the full resource type mapping, BIP module HCL examples, and raw resource patterns.

#### 1e. Validate

```bash
terraform init -upgrade   # Pulls new AFD provider schemas
terraform validate        # Must pass before any state surgery
```

Read `references/provider-pitfalls.md` for common validation errors with azurerm v4.x.

### Step 2 — Remove Classic State

```bash
# Backup first
terraform state pull > state-backup-$(date +%Y%m%d-%H%M%S).json

# Remove old CDN resources (does NOT delete from Azure)
terraform state rm azurerm_cdn_profile.cdn_profile
terraform state rm azurerm_cdn_endpoint.my_endpoint
terraform state rm 'azurerm_cdn_endpoint_custom_domain.my_domain[0]'
# Repeat for all classic CDN resources
```

Quote addresses that contain index expressions (`[0]`, `["key"]`).

### Step 3 — Import AFD Resources

Import order: profile → secrets (if any) → endpoints → origin groups → origins → rule sets → rules → routes → custom domains.

**Resource ID base path:**
```
/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Cdn/profiles/{profile}
```

**Module vs flat addresses:** BIP module resources use `module.<name>.azurerm_cdn_frontdoor_<type>.<internal-name>`. Verify internal names by inspecting `.terraform/modules/<module-name>/`. Read `references/resource-mapping.md` for the full import ID table and address patterns.

**Example imports:**

```bash
SUB="your-subscription-id"
RG="your-resource-group"
PROFILE="your-afd-profile"
BASE="/subscriptions/$SUB/resourceGroups/$RG/providers/Microsoft.Cdn/profiles/$PROFILE"

# Profile — BIP module
terraform import 'module.cdn_frontdoor_profile.azurerm_cdn_frontdoor_profile.frontdoor_profile' "$BASE"

# Secret — raw resource (customer-certificate environments only)
terraform import 'azurerm_cdn_frontdoor_secret.root_domain_cert[0]' \
  "$BASE/secrets/your-secret-name"

# Endpoint — BIP module
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint' \
  "$BASE/afdEndpoints/my-endpoint-name"

# Origin group — BIP module
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group' \
  "$BASE/originGroups/my-origin-group-Default"

# Origin — BIP module
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_origin.frontdoor_origin' \
  "$BASE/originGroups/my-origin-group-Default/origins/my-origin-name"

# Rule set — BIP module
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_rule_set.rule_set' \
  "$BASE/ruleSets/MigratedMyEndpoint"

# Route — BIP module
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_route.frontdoor_route' \
  "$BASE/afdEndpoints/my-endpoint-name/routes/myroutename"

# Custom domain — BIP module (keyed)
terraform import 'module.my_endpoint.azurerm_cdn_frontdoor_custom_domain.custom_domains["my-domain"]' \
  "$BASE/customDomains/my-custom-domain-name"

# Raw (non-module) resources use flat addresses
terraform import 'azurerm_cdn_frontdoor_rule.my_rule' \
  "$BASE/ruleSets/MigratedMyRawEndpoint/rules/Global"
```

**Cannot be imported:** `azurerm_cdn_frontdoor_custom_domain_association` — synthetic Terraform-only resource, no Azure counterpart. Terraform will plan to create these; accept it.

**Remote backend note:** `terraform import` may require `-var-file` to supply variables. Do NOT add `-var-file` to `plan`/`apply` when the remote backend supplies variables.

**Module-managed rule note:** if `terraform plan` later shows a module-managed HTTPS rule as `to add`, verify whether Azure already created that rule. If it already exists, import it instead of accepting the create.

### Step 4 — Validate Plan

```bash
terraform plan
```

**Target:** `0 to destroy`. In practice, expect some adds and changes after import.

**Zero destroys rule:** If the plan shows any destroys, stop. A destroy means a missed import or mismatched resource address.

Adds and changes are acceptable only when categorized and understood. Synthetic custom-domain associations, route origin-ID drift, identity changes, and intentional HTTPS hardening are often valid. Cache or compression removal is not.

Read `references/plan-drift.md` for the full categorization of expected vs problematic drift and reconciliation patterns.

### Step 5 — Apply

```bash
terraform apply
```

Monitor Sentinel policies and cost estimation for remote backends. The plan from Step 4 must contain zero destroys, and every add/change must be intentionally accepted before applying.

### Step 6 — Post-Apply Verification

```bash
# Test custom domains
curl -sI https://your-custom-domain.example.com | head -5

# Verify HTTPS redirect
curl -sI http://your-custom-domain.example.com | grep -i location

# Check cache headers
curl -sI https://your-custom-domain.example.com/some-asset.js | grep -i cache-control

# Confirm clean state
terraform plan   # Must show: No changes
```

---

## Multi-Environment Strategy

1. Complete the full migration (Portal + Terraform) on the lowest environment first.
2. Validate, apply, and verify before moving to the next environment.
3. Use the migration lock variable from Step 1a to prevent accidental runs.

Ideally, resource names follow the same pattern across environments. But the user may customize endpoint names when migrating in Azure Portal, so there are potential inconsistencies. Environment-specific naming patterns can be stored explicitly:

```hcl
locals {
  afd_endpoint_names = {
    test = { endpoint01 = "actual-test-endpoint-name" }
    live = { endpoint01 = "actual-live-endpoint-name" }
  }

  afd_route_names = {
    test = { endpoint01 = "actual-test-route-name" }
    live = { endpoint01 = "actual-live-route-name" }
  }

  afd_rule_set_names = {
    test = { endpoint01 = "actual-test-rule-set-name" }
    live = { endpoint01 = "actual-live-rule-set-name" }
  }
}
```

---

## Rollback

### Before Apply (Steps 0–4)

```bash
terraform state push state-backup-YYYYMMDD-HHMMSS.json
git revert <migration-commit>
```

### After Apply (Steps 5+)

- Resources imported and unchanged: no rollback needed.
- Resources modified (health probes, HTTPS settings): write new HCL restoring old values and re-apply.
- Resources created (domain associations, HTTPS rules): revert HCL and re-apply.
- **The Portal migration itself is irreversible.** Classic Azure CDN is gone. Terraform state migration only changes tracking.

---

## Cleanup Checklist

**Immediate:**
- [ ] Run `terraform plan` — confirm no changes after apply
- [ ] Remove migration lock variable (or retain as permanent guard)

**Short-term:**
- [ ] Remove legacy `*.azureedge.net` custom domains once old DNS TTLs expire
- [ ] Re-enable `certificate_name_check_enabled = true` on origins (verify TLS chain first)
- [ ] Remove `TODO` comments after all environments complete migration

**Long-term:**
- [ ] Archive migration scripts and documentation
- [ ] Consider renaming Portal-generated resource names to your convention (requires destroy + recreate — only if naming consistency outweighs downtime risk)

---

## Error Handling

| Problem | Cause | Fix |
|---|---|---|
| `terraform validate` fails | azurerm v4.x attribute name change | Read `references/provider-pitfalls.md` |
| Plan shows destroys | Missed import or wrong resource address | Re-import at correct address; do not apply |
| Import fails with "resource already managed" | Resource address already in state | Run `terraform state rm` first, then re-import |
| Plan shows constant drift on `cdn_frontdoor_origin_ids` | Provider import quirk | Accept — it is harmless |
| Plan removes `cache` block or compression settings | HCL doesn't match Azure state | Read `references/plan-drift.md` for reconciliation HCL |
| `terraform import` fails on remote backend | Missing `-var-file` | Add `-var-file="environments/your-env.tfvars"` to import commands only |
| `azurerm_cdn_frontdoor_secret` wants replacement | HCL uses the wrong certificate URI form | Use the discovered secret name plus certificate `versionless_id` |
| Portal-generated names do not match HCL | Portal naming differs by environment | Store discovered names in env-specific maps or variables |
| Module HTTPS rule appears as create | The rule may already exist in Azure | Check Azure and import it if present |
| Placeholder URI fails validation | Provider validates KV URIs even for `count = 0` | Use a syntactically valid three-segment URI as placeholder, or switch to data-source lookup |
