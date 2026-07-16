# Resource Mapping Reference

## Classic CDN → AFD Resource Types

| Classic CDN (old HCL) | Azure Front Door (new HCL) |
|---|---|
| `azurerm_cdn_profile` | BIP module `app.terraform.io/afs/cdn_frontdoor_profile/azurerm` |
| `azurerm_cdn_endpoint` (standard) | BIP module `app.terraform.io/afs/cdn_frontdoor_endpoint/azurerm` |
| `azurerm_cdn_endpoint` (custom rules) | Raw `azurerm_cdn_frontdoor_endpoint` + `azurerm_cdn_frontdoor_origin_group` + `azurerm_cdn_frontdoor_origin` + `azurerm_cdn_frontdoor_route` |
| `azurerm_cdn_endpoint_custom_domain` | `azurerm_cdn_frontdoor_custom_domain` + `azurerm_cdn_frontdoor_custom_domain_association` (or `custom_domains` map in BIP module) |
| CDN Rules Engine (inline) | `azurerm_cdn_frontdoor_rule_set` + `azurerm_cdn_frontdoor_rule` (one per rule) |
| (no equivalent) | `azurerm_cdn_frontdoor_secret` (Key Vault-backed certificates) |

**Rule:** Use BIP modules by default. Use raw `azurerm_cdn_frontdoor_*` resources only for features not yet exposed by the modules. Both can coexist in the same profile — reference `module.cdn_frontdoor_profile.id` for the shared profile ID.

---

## Per-Endpoint Resource Inventory

| Resource | Terraform Type | Count |
|---|---|---|
| Endpoint | `azurerm_cdn_frontdoor_endpoint` | 1 |
| Origin Group | `azurerm_cdn_frontdoor_origin_group` | 1 |
| Origin | `azurerm_cdn_frontdoor_origin` | 1+ |
| Route | `azurerm_cdn_frontdoor_route` | 1 |
| Rule Set | `azurerm_cdn_frontdoor_rule_set` | 1 |
| Rules | `azurerm_cdn_frontdoor_rule` | N (check discovery) |
| Custom Domains | `azurerm_cdn_frontdoor_custom_domain` | N (real + legacy `.azureedge.net`) |
| Domain Associations | `azurerm_cdn_frontdoor_custom_domain_association` | 0–N (standalone only; BIP module embeds linkage) |

---

## Import ID Formats

Base path: `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Cdn/profiles/{profile}`

| Resource | Azure ID Path |
|---|---|
| Profile | `{base}` |
| Endpoint | `{base}/afdEndpoints/{name}` |
| Origin Group | `{base}/originGroups/{name}` |
| Origin | `{base}/originGroups/{og}/origins/{name}` |
| Route | `{base}/afdEndpoints/{ep}/routes/{name}` |
| Rule Set | `{base}/ruleSets/{name}` |
| Rule | `{base}/ruleSets/{rs}/rules/{name}` |
| Custom Domain | `{base}/customDomains/{name}` |
| Secret (KV cert) | `{base}/secrets/{name}` |

`azurerm_cdn_frontdoor_custom_domain_association` — **cannot be imported**. No Azure-side resource. Terraform creates it as a state-only linkage.

---

## BIP Module Internal Resource Names

When using BIP modules, the Terraform address includes the module path and the module's internal resource name. For `terraform import`, use these internal names:

| Module | Internal Resource Name |
|---|---|
| `cdn_frontdoor_profile` | `azurerm_cdn_frontdoor_profile.frontdoor_profile` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_origin.frontdoor_origin` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_rule_set.rule_set` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_route.frontdoor_route` |
| `cdn_frontdoor_endpoint` | `azurerm_cdn_frontdoor_custom_domain.custom_domains["{key}"]` |

Verify internal names by inspecting `.terraform/modules/<module-name>/` after `terraform init`.

---

## BIP Module HCL — Standard Endpoint

```hcl
module "my_endpoint" {
  source  = "app.terraform.io/afs/cdn_frontdoor_endpoint/azurerm"
  version = "~> 0.0.8"

  frontdoor_profile_id             = module.cdn_frontdoor_profile.id
  location                         = var.location
  tags                             = local.tags
  storage_account_primary_web_host = azurerm_storage_account.my_storage.primary_web_host
  storage_account_id               = azurerm_storage_account.my_storage.id

  frontdoor_endpoint = {
    name    = "my-endpoint-name"    # Must match Azure exactly
    enabled = true
  }

  frontdoor_origin_group = {
    name = "my-endpoint-Default"
    health_probe = {
      interval_in_seconds = 100
      path                = "/"
      protocol            = "Https"
      request_type        = "HEAD"
    }
    load_balancing = {
      additional_latency_in_milliseconds = 50
      sample_size                        = 4
      successful_samples_required        = 3
    }
  }

  frontdoor_origin = {
    name                           = "my-origin-name"
    certificate_name_check_enabled = true
  }

  frontdoor_route = {
    name                   = "myroutename"    # Must match Azure (no hyphens)
    https_redirect_enabled = true
    patterns_to_match      = ["/*"]
    supported_protocols    = ["Http", "Https"]
    forwarding_protocol    = "HttpsOnly"
    link_to_default_domain = true
  }

  https_enforcement_config = { enabled = true }

  frontdoor_rule_set_name = "MigratedMyEndpoint"    # Must match Azure

  # Include legacy *.azureedge.net domain to keep it attached to route
  additional_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.my_endpoint_migrated.id,
  ]

  custom_domains = {
    "my-custom-domain" = {
      host_name        = "my.example.com"
      certificate_type = "ManagedCertificate"
    }
  }
}
```

---

## `content_types_to_compress` Reference List

Do not assume a universal list. Preserve the exact list discovered per route in Azure, then reconcile intentionally.

During the recorded migration on azurerm `v4.63.0`, the final accepted HCL had to use the provider-accepted list below. `font/woff` and `font/woff2` were present in Azure state but were not accepted by the provider in the reconciled configuration.

```hcl
content_types_to_compress = [
  "application/javascript",
  "application/xml",
  "font/otf",
  "font/ttf",
  "image/svg+xml",
  "text/css",
  "text/html",
  "text/plain",
]
```

If Azure shows extra content types that the provider rejects, reconcile to the provider-accepted list before apply.
