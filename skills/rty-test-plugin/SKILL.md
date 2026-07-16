---
name: rty-test-plugin
description: "Validation skill for the rty-aip-hub subtree external plugin strategy. Use when testing whether an externally-maintained plugin repo appears correctly in the marketplace."
---

# rty-test-plugin

This is a minimal validation skill. If you can read this, the subtree-based external plugin strategy is working correctly.

## What to check

1. This plugin appears in the marketplace listing in Claude Desktop, Codex, and Cursor
2. Installing it deploys this skill file to `.agents/skills/rty-test-plugin/SKILL.md`
3. The skill is discoverable and its description matches what was shown in the marketplace

## Validation response

When asked to validate, confirm:
- Plugin name: `rty-test-plugin`
- Source: `diogolopesAV/rty-test-plugin` (external repo, vendored via git subtree into the hub)
- Skills: 1 skill loaded successfully
