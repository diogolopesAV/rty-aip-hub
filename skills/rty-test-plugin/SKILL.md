---
name: rty-test-plugin
description: "Validates that the rty-test-plugin is installed and all its primitives (skills, hooks, MCP, rules) are active. Run this when setting up or troubleshooting the plugin."
---

# rty-test-plugin Validation Skill

Use this skill to confirm the plugin is fully installed and operating correctly across all active primitives.

## What to verify

When asked to validate the plugin or run a plugin check, confirm each of the following:

### 1. Skill loading
- This skill text is readable — the `skills/` primitive is working.
- Skill is namespaced as `rty-test-plugin:rty-test-plugin` in Claude Code / Copilot CLI.

### 2. Hooks (Claude Code, Cursor, Copilot CLI)
- A `SessionStart` hook should have fired when this session began, printing a banner to the terminal.
- A `PreToolUse` hook is active on `Bash` tool calls — it logs the command being run.
- **Note:** Codex CLI does NOT support hooks at the plugin layer — hooks there only work at the user/repo config layer (`~/.codex/hooks.json`), not in plugin manifests.

### 3. MCP server (Claude Code, Copilot CLI, Cursor, Codex CLI)
- `.mcp.json` (Claude/Copilot) and `mcp.json` (Cursor) declare a `memory` MCP server (`@modelcontextprotocol/server-memory`).
- If MCP is active, the tool `memory__create_entities` (or similar) should be available.
- Run: list available tools and check for `memory__` prefixed tools.

### 4. Rules (Cursor only)
- `rules/rty-test-plugin.mdc` is loaded when this plugin is active in Cursor.
- The rule is non-applied by default (`alwaysApply: false`) — it activates when relevant.
- Other platforms ignore the `rules/` directory entirely.

## Validation response

Summarize findings in this format:

```
rty-test-plugin validation
--------------------------
Skill:   ✓ loaded (you are reading this)
Hooks:   [✓ active | — not applicable (Codex: plugin-layer hooks not supported)]
MCP:     [✓ memory server available | ✗ not detected]
Rules:   [✓ Cursor rule active | — not applicable on this platform]
```
