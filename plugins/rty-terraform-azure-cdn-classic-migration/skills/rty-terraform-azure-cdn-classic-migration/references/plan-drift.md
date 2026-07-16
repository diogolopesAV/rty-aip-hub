# Common Plan Drift After Import

After importing all AFD resources, `terraform plan` will almost always show changes. Categorize every planned change before deciding to apply.

**Hard rule: Zero destroys.** If the plan wants to destroy anything, stop and investigate.

---

## Category 1 — Always Expected (Accept)

| Change | Reason | Action |
|---|---|---|
| `azurerm_cdn_frontdoor_custom_domain_association` — create | Synthetic Terraform-only resource; has no Azure counterpart | Accept |
| `cdn_frontdoor_origin_ids` — empty → populated | Provider import quirk | Accept |
| Module-internal resources (e.g., HTTPS enforcement rules) — create | Module creates resources that may or may not already exist in Azure after Portal migration | Verify in Azure first, then import if present or accept the create if absent |
| `identity` block — add SystemAssigned | Module/HCL adds managed identity only when the Portal migration did not already add it | Accept if Azure lacks the identity; otherwise expect no diff |

---

## Category 2 — Intentional Improvements (Accept)

The Portal migration uses Azure bare defaults. HCL authoring typically improves them:

| Attribute | Portal Default | Typical HCL Value |
|---|---|---|
| `forwarding_protocol` | `MatchRequest` | `HttpsOnly` |
| `https_redirect_enabled` | `false` | `true` |
| Health probes | None configured | Configured |
| `restore_traffic_time_to_healed_or_new_endpoint_in_minutes` | `0` | `10` |
| `response_timeout_seconds` | `30` | `60`–`120` |
| `additional_latency_in_milliseconds` | `0` | `50` |

---

## Category 3 — Needs Reconciliation (Update HCL)

These changes would remove existing Azure configuration. Update HCL to match Azure's current state before applying.

| Change | Symptom | Fix |
|---|---|---|
| Route `cache` block removal | HCL has no `cache {}` block but Azure has one | Add `cache {}` block with values matching Azure |
| Rule `compression_enabled` removal | Azure has `compression_enabled = true`, HCL omits it | Add `compression_enabled = true` to rule actions |
| Rule `query_string_caching_behavior` removal | Azure has a value, HCL doesn't set it | Add `query_string_caching_behavior` to rule actions |
| `content_types_to_compress` shrinking | Module default list is smaller than Azure's actual list | Pass explicit `content_types_to_compress` matching Azure |

---

## Reconciliation HCL Patterns

### Route-Level Cache Block

```hcl
resource "azurerm_cdn_frontdoor_route" "my_route" {
  # ... other attributes ...

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress     = [
      "application/javascript",
      "application/xml",
      "font/otf",
      "font/ttf",
      "image/svg+xml",
      "text/css",
      "text/html",
      "text/plain",
    ]
  }
}
```

### Rule-Level Cache Override

```hcl
actions {
  route_configuration_override_action {
    cache_behavior                = "OverrideIfOriginMissing"
    cache_duration                = "12:00:00"
    compression_enabled           = true
    query_string_caching_behavior = "IgnoreQueryString"
  }
}
```

---

## Diagnostic Technique

To identify the source of unexpected drift, narrow the plan to a single resource address:

```bash
terraform plan -target='module.my_endpoint.azurerm_cdn_frontdoor_route.frontdoor_route'
```

Then compare the `+` / `~` / `-` attributes against what Azure currently shows:

```bash
az afd route show \
  --profile-name $PROFILE \
  --endpoint-name $ENDPOINT \
  --route-name $ROUTE \
  -g $RG \
  -o json
```

Match the HCL attribute values to the Azure JSON values. Pay particular attention to nested blocks (`cache`, `actions`, `conditions`) that the import may not fully populate.

If Azure shows a rule that Terraform wants to create, verify whether it is already present under a module-managed address before applying. The correct response may be an import, not an accepted create.
