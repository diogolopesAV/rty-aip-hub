# Riverty AI Package Hub

A curated catalog of AI skills and packages for Riverty teams, built on [APM (Agent Package Manager)](https://microsoft.github.io/apm/). Register this hub as a marketplace once and install any package à-la-carte, or use a scoped bundle to install all packages for your team in one command.

---

## Install APM CLI

```bash
curl -sSL https://aka.ms/apm-unix | sh
```

---

## Marketplace (recommended)

Register the hub once, then install packages by name:

```bash
apm marketplace add diogolopesAV/rty-aip-hub
apm marketplace browse rty-hub
```

Install in an existing project (APM auto-detects your runtime from `.claude/`, `.cursor/`, etc.):

```bash
apm install rty-web-accessibility@rty-hub
apm install rty-atlassian-mcp@rty-hub
```

In a fresh directory, pass `--target` explicitly:

```bash
apm install rty-web-accessibility@rty-hub --target claude
apm install rty-atlassian-mcp@rty-hub --target cursor
```

Install globally across all projects:

```bash
apm install -g rty-skill-authoring@rty-hub
```

---

## Scoped Bundles

Install all packages for your team in one command — no marketplace registration needed:

```bash
# AI teams (Atlassian MCP + skill authoring)
apm install diogolopesAV/rty-aip-hub/bundles/ai --target claude

# BIP teams (Python + Terraform coding standards)
apm install diogolopesAV/rty-aip-hub/bundles/bip --target claude
```

> **Note:** `bip-python-skill` and `bip-terraform-skill` are private repos. Set `GITHUB_APM_PAT` before installing — see [Authentication](#authentication).

---

## Full Platform Baseline

Install everything in one command:

```bash
apm install diogolopesAV/rty-aip-hub --target claude
```

---

## Available Packages

| Package | What it does |
|---------|-------------|
| `rty-atlassian-mcp` | Configure Atlassian's cloud MCP server for Jira and Confluence access |
| `rty-skill-authoring` | Create and validate agent skills following Riverty conventions |
| `rty-web-accessibility` | Ensure HTML/CSS is WCAG 2.1/2.2 Level AA compliant using Riverty web components |
| `rty-terraform-azure-cdn-classic-migration` | Guide Azure CDN Classic → Azure Front Door migration for Terraform environments |
| `bip-python-skill` | Python coding practices following BIP standards (private) |
| `bip-terraform-skill` | Terraform IaC coding practices following BIP standards (private) |

---

## Authentication

`bip-python-skill` and `bip-terraform-skill` are in the private `Riverty-Tech-Innovation` org. Any install that includes these packages requires a GitHub PAT with `contents:read` access.

```bash
# Simplest — if GitHub CLI is already authenticated:
gh auth login
# APM auto-detects gh credentials — no extra setup needed.

# Without gh CLI — export a PAT with contents:read on Riverty-Tech-Innovation:
export GITHUB_APM_PAT=ghp_your_token_here
```

Once set, all APM commands — `apm marketplace add`, `apm install`, bundle installs — resolve private repos automatically.

---

## Contributing

To add a new package, open a PR that adds a new directory under `packages/` and registers it in `apm.yml`.

### Package layout

```
packages/your-package-name/
  SKILL.md          ← required: name + description frontmatter, then skill content
  assets/           ← templates, config files, static output (optional)
  references/       ← schemas, API docs, cheatsheets loaded on demand (optional)
  scripts/          ← deterministic scripts as tiny CLIs (optional)
```

`SKILL.md` frontmatter needs only `name` and `description`:

```yaml
---
name: rty-your-package-name
description: "One sentence. Use when X. Do not use for Y."
---
```

### Register in `apm.yml`

```yaml
# In marketplace.packages:
- name: rty-your-package-name
  source: ./packages/rty-your-package-name
  description: "One sentence."
  tags: [skill, your-domain]

# In dependencies.apm:
- diogolopesAV/rty-aip-hub/packages/rty-your-package-name
```

For packages hosted in external repos (not this repo):

```yaml
# In marketplace.packages:
- name: external-package
  source: org/repo
  ref: v1.0.0
  description: "One sentence."
  tags: [skill, domain]

# In dependencies.apm:
- org/repo#v1.0.0
```

### Tag conventions

| Tag | Use for |
|-----|---------|
| `skill`, `plugin`, `mcp`, `hook` | Content type |
| `ai`, `design-system`, `bip`, `azure`, `security` | Domain |
| `python`, `terraform`, `react`, `playwright` | Technology |
| `accessibility`, `migration`, `workflow` | Topic |

### Supported package layouts

APM auto-detects the package type from the repo structure:

| Layout | Detected as |
|--------|-------------|
| `SKILL.md` at root | Skill Bundle |
| `skills/<name>/SKILL.md` | Skill Collection |
| `plugin.json` at root | Plugin Collection |
| `.apm/` directory | APM Package (skills + agents + commands + hooks) |
| `hooks/*.json` only | Hook Package |

### If the package belongs to an existing bundle

Add its entry to the relevant bundle under `bundles/<domain>/apm.yml`:

```yaml
dependencies:
  apm:
    - diogolopesAV/rty-aip-hub/packages/rty-your-package-name
```

### If you're creating a new domain bundle

Create `bundles/<domain>/apm.yml` when a domain has 2 or more packages. Use an existing bundle as reference:

```yaml
name: rty-hub-<domain>
version: 1.0.0
description: "Riverty <domain> bundle — short description"
license: MIT
dependencies:
  apm:
    - diogolopesAV/rty-aip-hub/packages/rty-first-package
    - diogolopesAV/rty-aip-hub/packages/rty-second-package
```

**Current bundle status:**

| Bundle | Domain | Packages |
|--------|--------|---------|
| `bundles/ai` | AI tooling | `rty-atlassian-mcp`, `rty-skill-authoring` |
| `bundles/bip` | BIP standards | `bip-python-skill`, `bip-terraform-skill` |
| `bundles/design-system` | _(not yet created)_ | Waiting for a second design-system package alongside `rty-web-accessibility` |

### CI

Opening a PR runs `apm pack --dry-run --check-clean` to validate all source refs. Merging to main regenerates `.claude-plugin/marketplace.json` automatically.

### Reproducing an exact environment

Once a project has an `apm.lock.yaml`, teammates can reproduce it exactly:

```bash
apm install --frozen
```

---

## Repository Structure

```
rty-aip-hub/
├── apm.yml                          # Marketplace catalog + full baseline install
├── .claude-plugin/
│   ├── marketplace.json             # Generated by CI — powers apm marketplace add
│   └── plugin.json                  # Hub identity manifest
├── .github/
│   ├── plugin/plugin.json           # Copilot plugin manifest (generated by CI)
│   └── workflows/
│       ├── pack.yml                 # Regenerates marketplace.json on merge to main
│       └── validate-pr.yml          # Validates entries on PR
├── bundles/
│   ├── ai/apm.yml                   # AI skills bundle
│   └── bip/apm.yml                  # BIP team bundle
└── packages/
    ├── rty-atlassian-mcp/           # Atlassian MCP setup skill
    ├── rty-skill-authoring/         # Skill authoring meta-skill
    ├── rty-web-accessibility/       # Web accessibility skill
    └── rty-terraform-azure-cdn-classic-migration/  # CDN → AFD migration skill
```
