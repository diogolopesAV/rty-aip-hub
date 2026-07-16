# Progressive Disclosure

Detailed rules for managing context window efficiency through staged information loading.

## Principle

The agent's context window is a scarce resource. Load information only when the agent needs it. SKILL.md acts as a router — it tells the agent *what* to do and *where* to find details, without including those details inline.

## Three-Layer Architecture

### Layer 1: Frontmatter (always visible)

- `name` and `description` fields only.
- The agent sees this before deciding to trigger the skill.
- Budget: under 1024 characters for description.

### Layer 2: SKILL.md (loaded on trigger)

- High-level procedures, decision trees, and navigation.
- Budget: under 500 lines.
- Contains explicit commands to read Layer 3 files when needed.

### Layer 3: Subdirectory files (loaded on demand)

- `references/`: Domain knowledge, schemas, error taxonomies, API docs.
- `assets/`: Templates, boilerplate, static output files.
- `scripts/`: Executable code for deterministic tasks.
- Loaded only when SKILL.md directs the agent to read them.

## What Stays in SKILL.md

Keep in SKILL.md:

- The numbered workflow (Steps 1–N).
- Decision trees with explicit branching ("If X, do A. Otherwise, do B.").
- Tables summarizing when to use which reference file.
- Error handling tables mapping problems to fixes.
- Constraints and rules that apply to every execution.

## What Moves to References

Move to `references/` when content:

- Exceeds 30 lines on a single subtopic.
- Applies only to a specific branch of the workflow.
- Contains detailed schemas, API specifications, or error code lists.
- Would only be needed in some executions, not all.

## What Moves to Assets

Move to `assets/` when content:

- Is a template to be copied or filled in during output.
- Is a static file to be included in the skill's output verbatim.
- Is a configuration file the agent must produce.

## What Moves to Scripts

Move to `scripts/` when the task:

- Requires exact, deterministic output (no variation is acceptable).
- Involves complex parsing, data transformation, or calculation.
- Would be error-prone if the agent wrote it from scratch each time.
- Needs to interact with external tools or APIs in a specific way.

## JiT Loading Syntax

Use explicit imperative commands to direct the agent:

**Good examples:**
- "Read `references/error-codes.md` for the full error taxonomy."
- "Use the template at `assets/config.template.json` as the base configuration."
- "Run `scripts/validate.py --input {file}` to check the output."

**Bad examples:**
- "See the references folder for more info." (Too vague — which file?)
- "Check the documentation." (Not actionable — what documentation where?)
- "The following schema applies..." followed by 200 lines of JSON. (Inline bloat.)

## File Organization Rules

1. **One level deep only.** `references/auth.md` is correct. `references/auth/v2/tokens.md` is not.
2. **Forward slashes only.** Use `/` regardless of operating system.
3. **Descriptive filenames.** `VALIDATION_GUIDE.md` tells the agent what it will find. `doc2.md` does not.
4. **No documentation-for-humans.** Do not create `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, or `INSTALLATION_GUIDE.md` inside the skill directory. These are for human consumption and waste tokens.

## Measuring Success

A skill has good progressive disclosure when:

- SKILL.md alone is sufficient for the agent to understand the workflow.
- Reference files are read only when the agent is on the relevant workflow branch.
- The agent never loads a file it doesn't end up using.
- Total SKILL.md size stays under 500 lines across revisions.
