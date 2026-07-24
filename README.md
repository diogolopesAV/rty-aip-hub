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
apm install rty-sample-skills-only@rty-hub
apm install rty-sample-integration@rty-hub
```

In a fresh directory, pass `--target` explicitly:

```bash
apm install rty-sample-skills-only@rty-hub --target claude
apm install rty-sample-integration@rty-hub --target cursor
```

Install globally across all projects:

```bash
apm install -g rty-sample-hooks@rty-hub
```

---

## Scoped Bundles

Install all packages for your team in one command — no marketplace registration needed:

```bash
# Core sample fixtures (skills-only + hooks)
apm install diogolopesAV/rty-aip-hub/bundles/sample-core --target claude

# Extended sample fixtures (MCP+agents + rules)
apm install diogolopesAV/rty-aip-hub/bundles/sample-extended --target claude
```

---

## Full Platform Baseline

Install everything in one command:

```bash
apm install diogolopesAV/rty-aip-hub --target claude
```

---

## Available Packages

**Sample/fixture plugins** (Riverty-owned, maintained in this repo under `plugins/`)

These are deliberately synthetic plugins used to validate the marketplace catalog, primitive detection, and install flow end-to-end. Replace with real team plugins as they come online.

| Package | Primitives | What it does |
|---------|-----------|-------------|
| `rty-sample-skills-only` | skill | Minimal fixture — a single skill, nothing else |
| `rty-sample-hooks` | skill + hooks | Skill plus session/tool lifecycle hooks |
| `rty-sample-integration` | skill + MCP + agent | Skill plus an in-memory MCP server and a validation agent |
| `rty-sample-governed` | skill (multi-file) + rules | Multi-file skill (`SKILL.md` + `references/` + `assets/`) plus a Cursor-only rule |

**External**

| Package | What it does |
|---------|-------------|
| `rty-test-plugin` | Reference plugin demonstrating every supported primitive across all four services |

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
│   ├── sample-core/apm.yml          # Core sample bundle (skills-only + hooks)
│   └── sample-extended/apm.yml      # Extended sample bundle (MCP+agents + rules)
└── plugins/
    ├── rty-sample-skills-only/      # Skill-only fixture
    ├── rty-sample-hooks/            # Skill + hooks fixture
    ├── rty-sample-integration/      # Skill + MCP + agent fixture
    └── rty-sample-governed/         # Multi-file skill + rules fixture
```
