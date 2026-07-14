# azurerm Provider Pitfalls (v4.x)

All issues below were encountered during real migrations and are specific to azurerm provider v4.x. Behavior may differ in v3.x.

---

## `key_vault_certificate_id` not `key_vault_secret_id`

The attribute name changed between v3 and v4. The URL path also changes from `/secrets/` to `/certificates/`.

```hcl
# ❌ Wrong (v3)
secret {
  customer_certificate {
    key_vault_secret_id = "https://vault.vault.azure.net/secrets/cert/version"
  }
}

# ✅ Correct (v4)
secret {
  customer_certificate {
    key_vault_certificate_id = "https://vault.vault.azure.net/certificates/cert/version"
  }
}
```

---

## Use the Certificate `versionless_id` for Portal-Created AFD Secrets

When the Portal migration creates an AFD secret for a Key Vault-backed custom domain, Terraform state may contain the certificate URI without a version hash. Using the versioned certificate `.id` in HCL can then force replacement.

```hcl
# ❌ Wrong after import if Azure stored the versionless certificate URI
key_vault_certificate_id = data.azurerm_key_vault_certificate.root_domain[0].id

# ❌ Wrong path type
key_vault_certificate_id = data.azurerm_key_vault_certificate.root_domain[0].secret_id

# ✅ Correct for the observed Portal-created AFD secret behavior
key_vault_certificate_id = data.azurerm_key_vault_certificate.root_domain[0].versionless_id
```

Notes:

- `versionless_id` is not the same as the literal `/latest` URI segment.
- The provider expects a certificate URI, not a secret URI.
- Matching the imported Azure value avoids `-/+` replacement drift and allows KV renewals to flow through without Terraform edits.

---

## Cache Duration Format

The provider rejects the `d.HH:MM:SS` format when `d=0`.

```hcl
# ❌ Wrong — provider rejects "0." prefix
cache_duration = "0.12:00:00"

# ✅ Correct — omit day component for sub-24h durations
cache_duration = "12:00:00"

# ✅ Correct — include day component only for >= 1 day
cache_duration = "1.00:00:00"
```

---

## `url_redirect_action` Attribute Names

```hcl
# ❌ Wrong (v3 names)
url_redirect_action {
  redirect_type        = "Found"
  destination_protocol = "Https"
}

# ✅ Correct (v4)
url_redirect_action {
  redirect_type        = "Found"
  redirect_protocol    = "Https"
  destination_hostname = ""   # Required in v4; use "" to preserve original hostname
}
```

---

## Placeholder URIs Validated at Plan Time (count = 0)

The provider validates Key Vault URI format at plan time even for resources with `count = 0`:

```hcl
# ❌ Will fail validation even with count = 0
key_vault_certificate_id = "<TODO: fill in later>"

# ✅ Use a syntactically valid three-segment URI as placeholder
key_vault_certificate_id = "https://placeholder.vault.azure.net/certificates/placeholder/placeholder"
```

---

## `cdn_frontdoor_origin_ids` Always Shows Diff After Import

After importing a route, the `cdn_frontdoor_origin_ids` attribute often appears as a diff (empty → populated) even when the origin is already associated. This is a provider import quirk. **It is harmless — accept it.**

---

## `identity` Block May or May Not Drift After Profile Import

Behavior depends on the Portal workflow used for that environment:

- If the Portal migration did **not** create a managed identity, the module may show an identity addition after import.
- If the Portal migration **did** create a managed identity, there may be no identity drift at all.

Do not assume a profile-identity diff is always present. Confirm with `az afd profile show`.

---

## Rule Order Numbers Must Match Exactly

Azure rule order numbers are set during the Portal migration. When writing `azurerm_cdn_frontdoor_rule` HCL, the `order` attribute must match the order discovered in Azure exactly:

```bash
az afd rule list --profile-name $PROFILE -g $RG --rule-set-name $RS -o table
```

A mismatch in `order` causes Terraform to attempt a modify on the rule, which may fail or cause unexpected behavior.

---

## Route Name Pattern (No Hyphens)

Azure auto-generates route names without hyphens (e.g., `myrouteendpoint01`). When writing the `name` attribute in `azurerm_cdn_frontdoor_route`, use the exact name from Azure — including the absence of hyphens. The HCL must match what was discovered.

---

## Module vs Raw Resource Import Address

When using BIP modules, the Terraform state address uses the module path:

```
module.my_endpoint.azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group
```

Specifying a flat address like `azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group` will fail — `terraform import` will not find a matching resource block in HCL.

Inspect `.terraform/modules/<module-name>/` after `terraform init` to verify exact internal resource names.
