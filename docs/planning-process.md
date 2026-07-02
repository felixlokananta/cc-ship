# Planning Process

This document defines the canonical planning process the main agent follows when running `/ship` and `/shipplan`. It is a reference document — not an installed subagent.

**Discipline:** during planning, only read the codebase and history (Read, Grep, Glob, and read-only `gh`/`git` commands). Do not modify files except to write `.claude/plan.md`.

**Plan for a smaller executor.** The plan is handed to `@implementer`, which runs on Haiku and reads only `.claude/plan.md` — it has none of the conversation history, codebase exploration, or reasoning that produced the plan. Any decision, edge case, or judgment call left unresolved in the plan will not get resolved correctly by the implementer; it will either guess or silently skip it. So:
- Resolve every decision point in the plan itself (via clarifying questions if needed) — never write a step that requires the implementer to choose an approach.
- Spell out non-trivial logic concretely (see Output format below) rather than describing it abstractly.
- Before writing the plan, check it against the completeness rule below.

## Understanding the request

Determine which input type you received before doing anything else.

**Feature description** (plain text, no `#` reference)
- Go straight to codebase analysis using the description as context

**Issue number** (input contains `#N`)
1. Run `gh issue view <N> --comments` to fetch the full issue: title, body, labels, and all comments
2. Extract the core requirement and any acceptance criteria or edge cases mentioned in comments
3. Proceed to codebase analysis

**Issue by keyword or title** (vague reference — e.g. "the auth bug", "the login issue")
1. Run `gh issue list` to search for matching open issues
2. If ambiguous, ask the user to confirm the correct issue before continuing
3. Then proceed as the issue number path above

## Codebase analysis

Before planning, read enough of the codebase to understand:
- Which files are directly affected
- Which files are indirectly affected (imports, tests, migrations, config)
- Existing patterns to follow (naming conventions, error handling, test style)
- Any gotchas or risks (DB migrations, breaking API changes, auth implications)

## Clarifying questions

After codebase analysis, assess whether the request is still clear enough to plan without assumptions.

Ask clarifying questions if **any** of the following are true:
- The feature goal or success criteria are ambiguous
- The scope is unclear (e.g. "improve performance" — which part? how much?)
- Multiple reasonable interpretations exist and the choice materially affects the plan
- Key constraints are missing (e.g. must support existing API? backward-compatible? affects specific users only?)
- A GitHub issue is sparse, lacks acceptance criteria, or the comments add conflicting requirements
- The codebase reveals multiple valid approaches or conflicting patterns that require a decision

When asking, use the `AskUserQuestion` tool — do not ask questions in plain text. For each question:
- Provide 2–4 concrete options derived from the codebase (e.g. existing patterns, files found, reasonable approaches)
- Include a short description on each option explaining the tradeoff or implication
- Allow "Other" as a fallback so the user can supply a custom answer
- Ask at most 4 questions at once; group related decisions into a single question where possible

Do not proceed to writing the plan until the user has answered all questions.

Skip this step only when the request is unambiguous and all decisions are derivable from the codebase or issue content alone.

## Completeness check

Before writing the plan, map every requirement and acceptance criterion from the source (the request, or the issue's title/body/comments) to at least one implementation step. If something has no step covering it, add one — do not let a requirement fall through silently. If a requirement is intentionally not being addressed, list it under "Out of scope" rather than omitting it.

## Output format

Save the plan to `.claude/plan.md` using this structure:

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

Do NOT write full implementations or boilerplate in the plan — the implementer still writes the actual file changes. Do include short code/pseudocode snippets in a step's **Details** wherever the logic is non-trivial enough that two competent engineers could reasonably implement it differently. Stop as soon as `.claude/plan.md` is written and confirm to the user that the plan is ready for review.
