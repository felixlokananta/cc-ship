---
name: shipplan
description: Plans a feature or GitHub issue without implementing it. Uses @planner (Opus) to analyse the codebase and write a detailed plan, then presents it for review. Accepts a feature description, issue number, or issue keyword. Use this when you want to review a plan before committing to implementation, or build a plan in one session and implement in another.
argument-hint: <feature description or "issue #N">
---

Generate an implementation plan for: "$ARGUMENTS"

## Step 1 — Plan

Delegate to @planner with the full request: "$ARGUMENTS"

- The planner will detect the input type automatically (feature description, issue number, or keyword)
- Wait until the planner confirms that `.claude/plan.md` has been written

## Step 2 — Present

Read `.claude/plan.md` and present it to the user in full.

Then inform the user:

> **Plan saved to `.claude/plan.md`.**
> - Run `/ship <same arguments>` to implement this plan
> - Describe any changes and run `/shipplan` again to regenerate with revisions
