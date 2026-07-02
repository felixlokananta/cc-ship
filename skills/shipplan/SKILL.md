---
name: shipplan
description: Plans a feature or GitHub issue without implementing it. The main agent plans the work (following docs/planning-process.md, including live clarifying questions), then presents it for review. Accepts a feature description, issue number, or issue keyword. Use this when you want to review a plan before committing to implementation, or build a plan in one session and implement in another.
argument-hint: <feature description or "issue #N">
---

Generate an implementation plan for: "$ARGUMENTS"

## Step 1 — Plan

Follow `docs/planning-process.md` to produce `.claude/plan.md`.

1. **Detect input type** (within "$ARGUMENTS")
   - Plain text (feature description): go to codebase analysis
   - Contains `#N` (GitHub issue): run `gh issue view <N> --comments` first, extract core requirement and acceptance criteria, then go to codebase analysis
   - Vague keyword/title: run `gh issue list` to find the issue, ask user to confirm if ambiguous, then proceed as issue number path

2. **Codebase analysis:** read enough of the codebase to understand which files are directly and indirectly affected, existing patterns to match, and any risks/gotchas

3. **Clarifying questions:** assess whether the request is clear enough to plan without assumptions. If any of these are true, use `AskUserQuestion` to ask 2–4 concrete options (derived from codebase findings):
   - Feature goal or success criteria are ambiguous
   - Scope is unclear (e.g., "improve performance" — which part? how much?)
   - Multiple reasonable interpretations exist
   - Key constraints are missing
   - GitHub issue is sparse or comments add conflicting requirements
   - Codebase reveals multiple valid approaches
   
   Wait for the user to answer all questions before proceeding.

4. **Completeness check:** map every requirement/acceptance criterion from the source to at least one implementation step (or explicitly list it under Out of scope). The implementer is Haiku and only sees `.claude/plan.md` — it cannot resolve anything left ambiguous, so every step must be concrete enough to require no judgment call, with a short code/pseudocode snippet for any non-trivial logic and a **Verification** check.

5. **Write `.claude/plan.md`** in the fixed format (Source, Summary, Goal, Affected files, Implementation steps, Tests to write, Risks and gotchas, Out of scope). Do not write full implementations or boilerplate — do include snippets for non-trivial logic per step.

## Step 2 — Present

Read `.claude/plan.md` and present it to the user in full.

Then inform the user:

> **Plan saved to `.claude/plan.md`.**
> - Run `/ship <same arguments>` to implement this plan
> - Describe any changes and run `/shipplan` again to regenerate with revisions
