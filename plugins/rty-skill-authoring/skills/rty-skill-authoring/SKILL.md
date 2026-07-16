---
name: rty-skill-authoring
description: Creates, reviews, and refines agent skills following the agentskills.io specification and Riverty conventions. Use when the user wants to author a new skill, improve an existing skill's structure, optimize frontmatter for discoverability, apply progressive disclosure, or validate skill quality. Do not use for installing, distributing, or consuming existing skills, writing general documentation, or managing repository configuration.
---

# Skill Authoring

Create, review, and refine agent skills that follow the [agentskills.io spec](https://agentskills.io/specification) and Riverty conventions.

## Conventions


### General Rules

1. The skill name field and its parent directory name must match exactly.
2. Never include secrets, tokens, or passwords. Describe *how* to access private resources instead.
3. Internal/development skills go under `.agents/` and set `metadata.internal: true`.

### Naming

1. Use `rty-` as the default name prefix.
2. The user may choose a different name freely when authoring skills in their own repository.
3. Skills with the `rty-` prefix are eligible for contribution to `diogolopesAV/rty-aip-hub`, where they go under `plugins/` at repo root.

## Core Workflow

### Step 1: Determine Skill Scope

Identify the boundaries of the skill:

1. Define the single capability the skill provides. A skill solves one problem well.
2. Confirm the capability is reusable beyond a single project.
3. Decide placement based on repository conventions. Common patterns: `plugins/` for shared plugins in the hub, `.agents/` for internal-only skills. Check the repository root for guidance.
4. If the skill overlaps with an existing one, extend or refine that skill instead.

### Step 2: Create the Directory Structure

Create exactly this layout:

```
{skill-name}/
├── SKILL.md              # Required: Metadata + core instructions
├── scripts/              # Executable code (Python/Bash/Node) as tiny CLIs
├── references/           # Supplementary context (schemas, cheatsheets)
└── assets/               # Templates or static files used in output
```

Only create subdirectories that will contain files. Do not create empty folders.

### Step 3: Write the Frontmatter

The YAML frontmatter is the only metadata the agent sees before triggering a skill. It determines discoverability.

```yaml
---
name: {skill-name}
description: {trigger-optimized description}
---
```

Rules for the `name` field:

1. 1–64 characters. Lowercase letters, numbers, and hyphens only. No consecutive hyphens.
2. Default prefix is `rty-`. The user may choose a different name when working in their own repository.
3. Must match the parent directory name exactly.

Rules for the `description` field:

1. Maximum 1,024 characters.
2. Describe the capability in third person (e.g., "Creates...", "Analyzes...").
3. Include positive triggers: what tasks should activate this skill.
4. Include negative triggers: what tasks should *not* activate it.
5. Be domain-specific. Avoid vague terms like "helps with code" or "development tool."

**Bad:** "Helps with testing."
**Good:** "Creates and maintains Playwright end-to-end tests for Angular applications. Use when the user wants to write browser tests, set up test fixtures, or debug flaky selectors. Do not use for unit tests, API tests, or non-Angular frameworks."

### Step 4: Write the SKILL.md Body

SKILL.md is the skill's brain. Keep it under 500 lines. Use it for navigation and high-level procedures only.

Apply these writing rules:

1. **Third-person imperative voice.** Write "Extract the text..." not "I will extract..." or "You should extract..."
2. **Step-by-step numbering.** Define workflows as strict chronological sequences. Map decision trees explicitly (e.g., "Step 2: If source maps are needed, run `ng build --source-map`. Otherwise, skip to Step 3.").
3. **Consistent terminology.** Pick one term per concept and use it everywhere. Use domain-native terms (e.g., "template" not "HTML" in Angular context).
4. **No prose.** Replace paragraphs of explanation with numbered steps, tables, or bulleted constraints.
5. **JiT loading.** Reference files in `references/` and `assets/` with explicit read instructions (e.g., "Read `references/error-codes.md` for the full error taxonomy."). The agent will not see these files until directed.

Use the template at `assets/skill-template.md` as a starting point for new skills.

### Step 5: Offload Detail to Subdirectories

Apply progressive disclosure to minimize token usage. See `references/PROGRESSIVE_DISCLOSURE.md` for detailed rules.

Summary of what goes where:

| Content Type | Location | When Loaded |
|---|---|---|
| High-level workflow, decision trees | `SKILL.md` | On skill trigger |
| API docs, error taxonomies, schemas | `references/` | When agent needs detail |
| Output templates, boilerplate | `assets/` | When producing output |
| Deterministic scripts for fragile ops | `scripts/` | When executing a task |

Rules:

1. Keep files exactly one level deep (e.g., `references/schema.md`, not `references/db/v1/schema.md`).
2. Use relative paths with forward slashes, regardless of OS.
3. Do not create: `README.md`, `CHANGELOG.md`, `INSTALLATION_GUIDE.md`, or any documentation-for-humans files.
4. Do not duplicate knowledge the agent already has. Challenge every sentence: "Does the agent really need this?"

### Step 6: Bundle Scripts for Deterministic Tasks

If the skill involves fragile or repetitive operations where variation is a bug, provide a tested script.

1. Place scripts in the `scripts/` directory.
2. Write scripts as tiny CLIs with `argparse` (Python), `getopts` (Bash), or plain Node argument parsing.
3. Return results via stdout as JSON when possible.
4. Write descriptive, human-readable error messages to stderr so the agent can self-correct.
5. Do not bundle library code. Skills reference existing tools or contain single-purpose scripts only.
6. Keep repository tests outside distributable skill folders. In `diogolopesAV/rty-aip-hub`, do not add test files inside `plugins/<plugin>/`.

### Step 7: Validate the Skill

Run the validation sequence described in `references/VALIDATION_GUIDE.md`. It covers:

1. **Discovery validation** — Verify the frontmatter triggers correctly and doesn't false-trigger.
2. **Logic validation** — Simulate agent execution step-by-step to find ambiguities.
3. **Edge case testing** — Stress-test for failure states and missing fallbacks.
4. **Architecture refinement** — Enforce progressive disclosure and shrink token footprint.

Do not skip validation. An untested skill can mislead agents and produce incorrect output.

## Reviewing an Existing Skill

When asked to review or improve a skill:

1. Read the skill's `SKILL.md` and list all files in its directory tree.
2. Check frontmatter against Step 3 rules. Flag vague or missing negative triggers.
3. Count lines in `SKILL.md`. If over 500, identify content to extract to `references/`.
4. Verify all referenced files exist and paths use forward slashes.
5. Check for prose that should be procedural steps.
6. Check for redundant instructions the agent already knows.
7. Run the validation sequence from `references/VALIDATION_GUIDE.md`.

## Error Handling

Common failure modes and corrections:

| Problem | Cause | Fix |
|---|---|---|
| Skill never triggers | Vague or missing description | Rewrite with specific positive/negative triggers |
| Agent hallucinates steps | Ambiguous instructions in SKILL.md | Replace prose with explicit numbered steps |
| Context window overflow | Too much content in SKILL.md | Extract to `references/` with JiT loading |
| Script failures ignored | No error output from scripts | Add descriptive stderr messages with exit codes |
| Wrong skill triggers | Overlapping descriptions | Add negative triggers to both skills |
