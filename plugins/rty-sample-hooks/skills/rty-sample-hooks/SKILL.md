---
name: rty-sample-hooks
description: "Sample marketplace fixture pairing a skill with lifecycle hooks. Use when validating that the plugin catalog and installer correctly surface a plugin's hooks primitive."
---

# rty-sample-hooks

This sample plugin bundles one skill with lifecycle hooks (`sessionStart`, `preToolUse`). It exists purely to validate primitive detection (`hooks/` directory probing) and install behavior in the marketplace.

## When to use

Use this skill when asked to "run the rty-sample-hooks checklist."

## What to do

1. Confirm this file loaded successfully.
2. Look for a hook banner printed at session start (see `hooks/claude-codex.json`, `hooks/cursor.json`, or `hooks/copilot.json` depending on the current service).
3. Report: `rty-sample-hooks: ✓ skill loaded, hooks: <detected/not detected>.`
