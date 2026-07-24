---
name: rty-sample-governed
description: "Sample marketplace fixture with a multi-file skill (SKILL.md + references/ + assets/) plus a Cursor rule. Use when validating multi-file skill fetch/edit and the rules primitive."
---

# rty-sample-governed

This sample plugin's skill folder intentionally contains more than just `SKILL.md` — see `references/checklist.md` and `assets/example-config.json`. It exists to validate that the platform fetches and allows editing the *entire* skill folder, not just the top-level file, and that Cursor-only rules are detected correctly.

## When to use

Use this skill when asked to "run the rty-sample-governed checklist."

## What to do

1. Confirm this file loaded successfully.
2. Read `references/checklist.md` for the full validation checklist.
3. Report: `rty-sample-governed: ✓ skill loaded, rules: <detected/not applicable>.`
