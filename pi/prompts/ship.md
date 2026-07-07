---
description: Plan-then-implement workflow — plan with clarifying questions, pause for human review, delegate to the implementer subagent, verify, open a PR. Accepts a feature description or a GitHub issue reference like "issue #12".
argument-hint: <feature description or "issue #N">
---

Orchestrate a plan-then-implement workflow for: "$@"

## Step 1 — Plan

**Discipline:** during planning, only read the codebase and history (read, grep, find, ls, and read-only `gh`/`git` commands). Do not modify files except to write `.pi/plan.md`.

**Plan for a smaller executor.** The plan is handed to the `implementer` subagent, which reads only `.pi/plan.md` — it has none of the conversation history, codebase exploration, or reasoning that produced the plan. Any decision, edge case, or judgment call left unresolved in the plan will not get resolved correctly by the implementer; it will either guess or silently skip it. So:
- Resolve every decision point in the plan itself (via clarifying questions if needed) — never write a step that requires the implementer to choose an approach.
- Spell out non-trivial logic concretely rather than describing it abstractly.
- Before writing the plan, check it against the completeness rule below.

### 1a. Detect input type (within "$@")

- **Feature description** (plain text, no `#` reference): go straight to codebase analysis
- **Issue number** (contains `#N`): run `gh issue view <N> --comments` to fetch title, body, labels, and all comments; extract the core requirement and any acceptance criteria or edge cases; then proceed to codebase analysis
- **Issue by keyword or title** (vague reference — e.g. "the auth bug"): run `gh issue list` to find matching open issues; if ambiguous, ask the user to confirm the correct issue; then proceed as the issue number path

### 1b. Codebase analysis

Before planning, read enough of the codebase to understand:
- Which files are directly affected
- Which files are indirectly affected (imports, tests, migrations, config)
- Existing patterns to follow (naming conventions, error handling, test style)
- Any gotchas or risks (DB migrations, breaking API changes, auth implications)

### 1c. Clarifying questions

After codebase analysis, assess whether the request is still clear enough to plan without assumptions. Ask clarifying questions if **any** of the following are true:
- The feature goal or success criteria are ambiguous
- The scope is unclear (e.g. "improve performance" — which part? how much?)
- Multiple reasonable interpretations exist and the choice materially affects the plan
- Key constraints are missing (e.g. must support existing API? backward-compatible?)
- A GitHub issue is sparse, lacks acceptance criteria, or the comments add conflicting requirements
- The codebase reveals multiple valid approaches or conflicting patterns that require a decision

When asking, use the `question` tool — do not ask questions in plain text. For each question:
- Provide 2–4 concrete options derived from the codebase, each with a short description explaining the tradeoff
- The tool asks one question per call — make one call per decision, sequentially
- The tool has a built-in "type something" fallback for custom answers
- If the user cancels the tool, ask the question in plain text instead

Do not proceed to writing the plan until the user has answered all questions. Skip this step only when the request is unambiguous and all decisions are derivable from the codebase or issue content alone.

### 1d. Completeness check

Before writing the plan, map every requirement and acceptance criterion from the source (the request, or the issue's title/body/comments) to at least one implementation step. If something has no step covering it, add one — do not let a requirement fall through silently. If a requirement is intentionally not being addressed, list it under "Out of scope" rather than omitting it.

### 1e. Write `.pi/plan.md`

Create the `.pi/` directory if needed and save the plan to `.pi/plan.md` using this structure:

```markdown
# Plan: <short title>

## Source
<!-- GitHub issue URL or original request -->

## Summary
<!-- 2-3 sentence description of what this plan achieves -->

## Goal
<!-- One observable sentence: what must be true when this is done. If the source is a GitHub issue, derive this from its acceptance criteria. -->

## Affected files
<!-- List every file to create or modify and why -->

## Implementation steps

### Step 1: <title>
**File:** `path/to/file.py`
**What:** Exact description of the change
**Why:** Reason this is needed
**Details:** Function signatures, model fields, API shapes, edge cases to handle. Include a short code or pseudocode snippet for any non-trivial logic (tricky conditionals, parsing, algorithms) — the implementer should not have to invent the approach.
**Verification:** A concrete, mechanical check that this step worked (a command to run, its expected output/exit code, or a specific behavior to observe).

### Step 2: ...

## Tests to write
<!-- List test cases that cover the new behaviour -->

## Risks and gotchas
<!-- Migrations, breaking changes, performance concerns, auth implications -->

## Out of scope
<!-- Explicitly list anything NOT being done in this plan -->
```

Do NOT write full implementations or boilerplate in the plan — the implementer still writes the actual file changes. Do include short code/pseudocode snippets in a step's **Details** wherever the logic is non-trivial enough that two competent engineers could reasonably implement it differently.

## Step 2 — Review

Read `.pi/plan.md` and present it to the user in full.

Then ask:

> **Does this plan look correct?**
> - Reply `yes` to proceed with implementation
> - Describe any changes needed and the plan will be revised before implementing

Do not proceed to Step 3 until the user explicitly says `yes`.

If the user requests changes:
1. Re-run the planning phase (Step 1) with: `"$@ — revisions: <user feedback>"` — re-analyse the codebase if needed, ask clarifying questions, rewrite `.pi/plan.md`
2. Read the updated `.pi/plan.md` and present it to the user in full
3. Ask again — repeat this loop until the user explicitly says `yes`

## Step 3 — Implement

Once approved, delegate using the `subagent` tool:

- Call `subagent` with `{ "agent": "implementer", "task": "Read .pi/plan.md in full and execute each implementation step in order, following your standing instructions. When finished, report back with your ✅/⚠️/🧪/📝 sections." }`

The implementer will read `.pi/plan.md` and execute each step in order.

## Step 4 — Verify goal

Once the implementer reports back:

1. Read the `## Goal` line from `.pi/plan.md`
2. Check the implementer's report — do the completed steps and passing tests satisfy that goal?
   - **Yes** → proceed to Step 5
   - **No** → re-delegate via the `subagent` tool with task: `"Goal not yet met: <goal text>. Gap: <what's missing from the report>. Read .pi/plan.md and address the gap without changing already-completed steps."`
3. Repeat until the goal is satisfied or the implementer reports a blocker it cannot resolve

## Step 5 — Create Pull Request

Once the goal is verified:

1. Push the branch to remote:
   ```
   git push -u origin HEAD
   ```

2. Build the PR title from the **Summary** line in `.pi/plan.md`.

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

   🤖 Generated with pi via /ship
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
