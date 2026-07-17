---
name: rty-test-plugin
description: "Validates that rty-test-plugin is installed and all its primitives are active for the current service. Run this when setting up or troubleshooting the plugin."
---

# rty-test-plugin Validation Skill

When asked to validate the plugin or run a plugin check, verify each primitive below for the service you are running on, then produce the summary.

---

## 1. Identify the current service

| You are... | Service |
|---|---|
| Claude Code CLI or desktop app | **Claude Code** |
| ChatGPT Work or Codex mode in the ChatGPT desktop app | **Codex** |
| Cursor IDE | **Cursor** |
| `copilot` CLI in terminal | **Copilot CLI** |

---

## 2. Skills

**All services.** This skill loading confirms the `skills/` primitive is working. Report: `Skill: ✓ loaded`.

---

## 3. Hooks

Hooks fire automatically at session start. Look for a banner in the terminal output. What to expect varies by service:

| Service | Expected banner | Hook file | Format details |
|---|---|---|---|
| Claude Code | `[rty-test-plugin] Session started — Claude/Codex hooks active.` | `hooks/claude-codex.json` | Nested PascalCase format, no version field. Events: 30 total. |
| Codex | `[rty-test-plugin] Session started — Claude/Codex hooks active.` | `hooks/claude-codex.json` | Same format as Claude Code. Hooks require **user trust review** before executing — Codex skips them until approved. |
| Cursor | `[rty-test-plugin] Session started — Cursor hooks active.` | `hooks/cursor.json` | Flat camelCase format, no version field. Events: ~21 total. |
| Copilot CLI | `[rty-test-plugin] Session started — Copilot hooks active.` | `hooks/copilot.json` | Flat camelCase format, `"version": 1` required. Supports `bash`/`command`/`powershell` fields. Events: 13 total. |

If no banner appeared: hooks may not be active yet (Codex/Copilot require trust approval on first use), or the platform may not support plugin-bundled hooks.

---

## 4. MCP Server

**All services.** An in-memory MCP server (`@modelcontextprotocol/server-memory`) is declared.

- **Claude Code, Codex, Copilot CLI**: reads `.mcp.json` at plugin root.
- **Cursor**: reads `mcp.json` (no dot prefix) — different filename, identical content.

To verify: list available tools and look for `memory__` prefixed tools (e.g. `memory__create_entities`, `memory__search_nodes`). If present: `MCP: ✓ active`.

---

## 5. Agents

| Service | Agent file | How to invoke |
|---|---|---|
| Claude Code | `agents/rty-validator.md` | `@rty-validator` or Claude routes automatically |
| Cursor | `agents/rty-validator.md` | Same file — Cursor discovers all `.md` files in `agents/` |
| Copilot CLI | `copilot-agents/rty-validator.agent.md` | `/agent` → select `rty-validator`. Requires `.agent.md` extension — Copilot only discovers this extension. |
| Codex | Not available | Agents are not a documented plugin primitive for Codex. |

Note: `agents/` contains the canonical `.md` files shared by Claude Code and Cursor. `copilot-agents/` contains the Copilot-specific `.agent.md` copies. Both reference the same validation logic but have different frontmatter (`tools` field uses Claude names in `.md`, Copilot tool names in `.agent.md`).

---

## 6. Rules

**Cursor only.** `rules/rty-test-plugin.mdc` provides persistent guidance when this plugin is active. It is ignored by all other services.

To verify in Cursor: check the rules panel in Customize for a rule from rty-test-plugin.

---

## Validation summary

Report in this exact format:

```
rty-test-plugin validation — [SERVICE NAME]
-------------------------------------------
Skill:    ✓ loaded
Hooks:    ✓ active  /  ✗ not detected  /  ⏸ pending trust review (Codex/Copilot)
MCP:      ✓ memory server active (memory__* tools available)  /  ✗ not detected
Agents:   ✓ rty-validator available  /  — not supported on this service
Rules:    ✓ Cursor rule loaded  /  — not applicable on this service
```
