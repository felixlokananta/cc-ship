---
name: ship
description: Orchestrates a full plan-then-implement workflow. The main agent plans the work (following docs/planning-process.md, including live clarifying questions), pauses for human review, then delegates implementation to Haiku (@implementer). Accepts a feature description or a GitHub issue reference like "issue #12".
argument-hint: <feature description or "issue #N">
---

Orchestrate a plan-then-implement workflow for: "$ARGUMENTS"

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

## Step 2 — Review

Read `.claude/plan.md` and present it to the user in full.

Then ask:

> **Does this plan look correct?**
> - Reply `yes` to proceed with implementation
> - Describe any changes needed and the plan will be revised before implementing

Do not proceed to Step 3 until the user explicitly says `yes`.

If the user requests changes:
1. Re-run the planning phase (following `docs/planning-process.md`) with: `"$ARGUMENTS — revisions: <user feedback>"` — re-analyse the codebase if needed, ask clarifying questions, rewrite `.claude/plan.md`
2. Read the updated `.claude/plan.md` and present it to the user in full
3. Ask again — repeat this loop until the user explicitly says `yes`

## Step 3 — Implement

Once approved, delegate to @implementer.

The implementer will read `.claude/plan.md` and execute each step in order.

## Step 4 — Verify goal

Once the implementer reports back:

1. Read the `## Goal` line from `.claude/plan.md`
2. Check the implementer's report — do the completed steps and passing tests satisfy that goal?
   - **Yes** → proceed to Step 5
   - **No** → re-delegate to @implementer with: `"Goal not yet met: <goal text>. Gap: <what's missing from the report>. Address the gap without changing already-completed steps."`
3. Repeat until the goal is satisfied or the implementer reports a blocker it cannot resolve

## Step 5 — Create Pull Request

Once the goal is verified:

1. Push the branch to remote:
   ```
   git push -u origin HEAD
   ```

2. Build the PR title from the **Summary** line in `.claude/plan.md`.

3. Build the PR body using this template, filling each section from the plan and the implementer's report:

   ```
   ## Summary
   <plan's Summary section>

   ## Changes
   <implementer's ✅ completed steps>

   ## Tests
   <implementer's 🧪 section — what was written and whether it passes>

   ## Follow-up
   <implementer's 📝 section — omit this section if empty>

   🤖 Generated with [Claude Code](https://claude.ai/claude-code) via /ship
   ```

4. Create the PR targeting the `develop` branch:
   ```
   gh pr create --base develop --title "<title>" --body "<body>"
   ```

5. Output the PR URL to the user.

If `gh` is not available or there is no remote, skip PR creation and note it in the summary.

## Step 6 — Done

Summarise:
- PR URL (or reason it was skipped)
- What was implemented
- Any tests written
- Any follow-up items or known gaps
