---
name: rty-sample-integration
description: "Sample marketplace fixture pairing a skill with an MCP server and an agent. Use when validating that the plugin catalog correctly surfaces MCP and agents primitives."
---

# rty-sample-integration

This sample plugin bundles one skill with an in-memory MCP server (`.mcp.json`) and a validation agent (`rty-sample-integration-agent`). It exists to validate primitive detection (`.mcp.json` + `agents/` probing) and lazy skill/detail loading in the marketplace.

## When to use

Use this skill when asked to "run the rty-sample-integration checklist."

## What to do

1. Confirm this file loaded successfully.
2. List available tools and look for `memory__` prefixed tools (e.g. `memory__create_entities`). If present, the MCP server is active.
3. Report: `rty-sample-integration: ✓ skill loaded, MCP: <active/not detected>, agent: <available/not supported>.`
