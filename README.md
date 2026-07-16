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

**Riverty-owned**

| Package | What it does |
|---------|-------------|
| `rty-atlassian-mcp` | Configure Atlassian's cloud MCP server for Jira and Confluence access |
| `rty-skill-authoring` | Create and validate agent skills following Riverty conventions |
| `rty-web-accessibility` | Ensure HTML/CSS is WCAG 2.1/2.2 Level AA compliant using Riverty web components |
| `rty-terraform-azure-cdn-classic-migration` | Guide Azure CDN Classic → Azure Front Door migration for Terraform environments |

**External skill-only** (APM CLI only; no platform manifests)

| Package | What it does |
|---------|-------------|
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

To add a new package, open a PR that adds a new directory under `plugins/` and registers it in `apm.yml`.

### Package layout

Every package is a cross-platform plugin. The structure satisfies APM CLI, Claude Code, GitHub Copilot CLI, Codex CLI, and Cursor simultaneously:

```
plugins/your-package-name/
  .codex-plugin/
    plugin.json     ← Codex native marketplace manifest (strict schema, see below)
  .cursor-plugin/
    plugin.json     ← Cursor native marketplace manifest
  .claude-plugin/
    plugin.json     ← Claude Code + Copilot CLI manifest (both use this path)
  skills/
    your-package-name/
      SKILL.md      ← required: name + description frontmatter, then skill content
      assets/       ← templates, config files, static output (optional)
      references/   ← schemas, API docs, cheatsheets loaded on demand (optional)
      scripts/      ← deterministic scripts as tiny CLIs (optional)
```

APM detects `skills/<name>/SKILL.md` as a **Skill Collection** and installs each skill to `.agents/skills/<name>/SKILL.md` for all targets.

`SKILL.md` frontmatter needs only `name` and `description`:

```yaml
---
name: rty-your-package-name
description: "One sentence. Use when X. Do not use for Y."
---
```

**`.codex-plugin/plugin.json`** — strict schema (Codex validator rejects extra fields):

```json
{
  "name": "rty-your-package-name",
  "version": "1.0.0",
  "description": "Same as SKILL.md description.",
  "author": { "name": "Riverty Technology Innovation" },
  "license": "MIT",
  "skills": "./skills/",
  "interface": {
    "displayName": "Human-Readable Name",
    "shortDescription": "One sentence.",
    "longDescription": "Two to three sentences.",
    "developerName": "Riverty Technology Innovation",
    "category": "Developer Tools",
    "defaultPrompt": "Help me … (max 128 chars)"
  }
}
```

**`.cursor-plugin/plugin.json`** and **`.claude-plugin/plugin.json`** — only `name` is required, add `displayName`, `version`, `description`, `license`, and `"skills": "./skills/"` for a complete listing.

### Register in `apm.yml`

```yaml
# In marketplace.packages:
- name: rty-your-package-name
  source: ./plugins/rty-your-package-name
  description: "One sentence."
  tags: [skill, your-domain]

# In dependencies.apm:
- diogolopesAV/rty-aip-hub/plugins/rty-your-package-name
```

### External skill-only repos (APM CLI only)

Repos that only have `SKILL.md` and no platform manifests (e.g. private team repos) are referenced via APM-native external refs. They appear in APM CLI installs but not in native UI marketplaces:

```yaml
# In marketplace.packages:
- name: external-skill
  source: org/repo
  ref: <full-commit-sha>
  description: "One sentence."
  tags: [skill, domain]

# In dependencies.apm:
- org/repo#<full-commit-sha>
```

### Tag conventions

| Tag | Use for |
|-----|---------|
| `skill`, `plugin`, `mcp`, `hook` | Content type |
| `ai`, `design-system`, `bip`, `azure`, `security` | Domain |
| `python`, `terraform`, `react`, `playwright` | Technology |
| `accessibility`, `migration`, `workflow` | Topic |

### APM package detection

Hub packages use the **Skill Collection** layout (`skills/<name>/SKILL.md`). APM promotes each skill to `.agents/skills/<name>/SKILL.md` in the consuming project, and supports `apm install --skill <name>` for selective installation. The platform-specific manifests (`.codex-plugin/`, `.cursor-plugin/`, `.claude-plugin/`) are ignored by APM and consumed only by their respective native UIs.

### If the package belongs to a bundle

Add its entry to the relevant bundle under `bundles/<domain>/apm.yml`. To create a new bundle for a domain that has reached 2+ packages, use an existing bundle file as reference.

### CI

Opening a PR runs `apm pack --dry-run --check-clean` to validate all source refs. Merging to main regenerates `.claude-plugin/marketplace.json` automatically.

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
└── plugins/
    ├── rty-atlassian-mcp/           # Atlassian MCP setup skill
    ├── rty-skill-authoring/         # Skill authoring meta-skill
    ├── rty-web-accessibility/       # Web accessibility skill
    └── rty-terraform-azure-cdn-classic-migration/  # CDN → AFD migration skill
```
