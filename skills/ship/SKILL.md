---
name: ship
description: Orchestrates a full plan-then-implement workflow. Uses Opus (@planner) to analyse the codebase and write a detailed plan, pauses for human review, then uses Haiku (@implementer) to execute it. Accepts a feature description or a GitHub issue reference like "issue #12".
argument-hint: <feature description or "issue #N">
---

Orchestrate a plan-then-implement workflow for: "$ARGUMENTS"

## Step 1 — Plan

Delegate to @planner with the full request: "$ARGUMENTS"

- If the request references a GitHub issue number, the planner will fetch it via `gh issue view` before analysing the codebase
- Wait until the planner confirms that `.claude/plan.md` has been written

## Step 2 — Review

Read `.claude/plan.md` and present it to the user in full.

Then ask:

> **Does this plan look correct?**
> - Reply `yes` to proceed with implementation
> - Describe any changes needed and the plan will be revised before implementing

Do not proceed to Step 3 until the user explicitly says `yes`.

If the user requests changes:
1. Re-delegate to @planner with: `"$ARGUMENTS — revisions: <user feedback>"`
2. Wait until @planner confirms the updated `.claude/plan.md` has been written
3. Read the updated `.claude/plan.md` and present it to the user in full
4. Ask again — repeat this loop until the user explicitly says `yes`

## Step 3 — Implement

Once approved, delegate to @implementer.

The implementer will read `.claude/plan.md` and execute each step in order.

## Step 4 — Create Pull Request

Once the implementer reports back:

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

## Step 5 — Done

Summarise:
- PR URL (or reason it was skipped)
- What was implemented
- Any tests written
- Any follow-up items or known gaps
