# Validation Guide

Validate skills using LLM-assisted testing. Run these four stages in order after drafting or revising a skill.

## Execution Mode

When executing as an autonomous agent, adapt these stages as follows:

1. Treat each "prompt" below as an analysis to perform internally.
2. Replace "Open a fresh LLM chat" with "Perform the following analysis."
3. Generate the requested outputs (trigger prompts, edge cases, simulations) directly.
4. Apply findings immediately rather than waiting for human answers.

## Stage 1: Discovery Validation

Verify the YAML frontmatter triggers correctly and avoids false positives.

1. Open a fresh LLM chat.
2. Paste the following prompt, replacing the YAML block with the skill's actual frontmatter:

```
I am building an Agent Skill based on the agentskills.io spec.
Agents will decide whether to load this skill based entirely on the YAML metadata below.

---
name: {skill-name}
description: {skill-description}
---

Based strictly on this description:
1. Generate 3 realistic user prompts that should trigger this skill.
2. Generate 3 user prompts that sound similar but should NOT trigger this skill.
3. Critique the description: Is it too broad? Too narrow? Suggest an optimized rewrite.
```

3. Review the LLM's output. If any of the "should NOT trigger" prompts would plausibly match, the description is too broad. Add negative triggers.
4. If any of the "should trigger" prompts would not plausibly match, the description is too narrow. Broaden the positive triggers.
5. Optionally, test with the agent directly: give it a task that should trigger the skill and inspect whether it reads the skill file.

## Stage 2: Logic Validation

Ensure instructions are deterministic and the agent never needs to hallucinate missing steps.

1. Provide the LLM with the full `SKILL.md` content and the directory tree of supporting files.
2. Use this prompt:

```
Here is the full draft of my SKILL.md and the directory tree of its supporting files.

{paste directory tree}

{paste SKILL.md contents}

Act as an autonomous agent that has just triggered this skill.
Simulate your execution step-by-step based on a request to: {describe a realistic task}.

For each step, write out your internal monologue:
1. What exactly are you doing?
2. Which specific file/script are you reading or running?
3. Flag any Execution Blockers: Point out the exact line where you are forced
   to guess or hallucinate because the instructions are ambiguous.
```

3. For each execution blocker the LLM identifies, add explicit instructions to `SKILL.md` or create a new reference file.
4. Re-run the simulation until zero blockers remain.

## Stage 3: Edge Case Testing

Force the LLM to find vulnerabilities, unsupported configurations, and failure states.

1. Using the same chat context from Stage 2, send:

```
Switch roles. Act as a ruthless QA tester. Your goal is to break this skill.
Ask 3 to 5 highly specific, challenging questions about edge cases, failure
states, or missing fallbacks in the SKILL.md. Focus on:

- What happens when a referenced script fails?
- What if the user's project structure doesn't match assumptions?
- Are there implicit assumptions about the environment?
- What error messages does the agent see on failure?

Do not fix these issues yet. Just ask the numbered questions.
```

2. Answer each question. For each gap identified, decide whether to:
   - Add error handling to `SKILL.md`
   - Add a fallback script in `scripts/`
   - Document the limitation explicitly

## Stage 4: Architecture Refinement

Apply progressive disclosure and reduce token footprint.

1. Send:

```
Based on my answers to your edge-case questions, rewrite the SKILL.md file,
strictly enforcing the Progressive Disclosure design pattern:

1. Keep the main SKILL.md strictly as high-level steps using third-person
   imperative commands.
2. If there are dense rules, large templates, or complex schemas currently
   in the file, remove them. Tell me to create a new file in references/ or
   assets/, and replace the text in SKILL.md with a strict command to read
   that specific file only when needed.
3. Add a dedicated Error Handling section at the bottom incorporating my
   answers about failure states and fallbacks.
```

2. Review the LLM's proposed restructuring. Accept changes that genuinely reduce SKILL.md size while preserving clarity.
3. Verify the final SKILL.md is under 500 lines.
4. Verify every file referenced in SKILL.md actually exists in the directory tree.

## Completion Checklist

After all four stages, confirm:

- [ ] Frontmatter triggers correctly for intended tasks
- [ ] Frontmatter does not false-trigger for adjacent tasks
- [ ] Agent can execute all steps without guessing
- [ ] Edge cases have explicit error handling or documented limitations
- [ ] SKILL.md is under 500 lines
- [ ] All referenced files exist
- [ ] No secrets, tokens, or passwords in any file
- [ ] Skill name starts with `rty-` and matches directory name
