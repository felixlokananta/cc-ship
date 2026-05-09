# cc-ship Improvements Design

**Date:** 2026-05-08
**Scope:** Five targeted improvements to the existing `skills/ship/SKILL.md`, `agents/planner.md`, `agents/implementer.md`, and a new `/plan` skill.

---

## 1. Plan revision loop re-invokes @planner (`skills/ship/SKILL.md`)

**Problem:** When a user requests changes to the plan in Step 2, the current SKILL.md says "I'll update the plan before implementing" — but `/ship` (not `@planner`) makes the edit. Revisions bypass the planner's codebase analysis tools entirely.

**Design:** Step 2 becomes a loop:
- If the user says `yes` → proceed to Step 3
- If the user describes changes → re-invoke `@planner` with `"$ORIGINAL_REQUEST — revisions: <feedback>"`, wait for updated `plan.md`, re-read and re-present it, ask again
- Loop repeats until explicit `yes`

This ensures every revision goes through the same read-only codebase analysis the initial plan did.

---

## 2. Explicit input handling in @planner (`agents/planner.md`)

**Problem:** The planner documents the GitHub issue number path but leaves the feature description path implicit. `gh issue list *` is in the tool allowlist but never explained.

**Design:** Replace the single "When given a GitHub issue number" section with three explicit cases:

| Input type | Detection | Action |
|---|---|---|
| Feature description | Plain text, no `#` | Go straight to codebase analysis using the description as context |
| Issue number | Contains `#N` | `gh issue view <N> --comments`, extract requirements, then codebase analysis |
| Issue by keyword/title | Vague reference (e.g. "the auth bug") | `gh issue list` to find matching issues, confirm the right one, then proceed as issue number path |

---

## 3. Implementer test runner + git workflow + ambiguity rule (`agents/implementer.md`)

### Tool allowlist addition
Add `Bash(make *)` — scoped to `make`, tight enough to avoid arbitrary shell execution.

### After each step (updated)
1. If a Makefile exists, run `make test` and note whether tests pass
2. Commit: `git add -A && git commit -m "step N: <what was done>"`
3. Flag any blockers or test failures immediately — do not continue to the next step

### Ambiguity rule (new)
If a step is ambiguous, stop and ask. Never guess and proceed.

### Completion report (updated)
- ✅ Steps completed
- ⚠️ Blockers or deviations (and why)
- 🧪 Tests written, whether they pass (`make test` output summary)
- 📝 Follow-up items for the next session

---

## 4. New `/plan` skill (`skills/plan/SKILL.md`)

A thin skill that exposes planning without committing to implementation.

**Behavior:**
1. Delegate to `@planner` with `$ARGUMENTS` (accepts feature description, issue number, or keyword — same as @planner)
2. Wait until `@planner` confirms `plan.md` is written
3. Read `plan.md` and present it to the user in full
4. Stop — no implementation phase

**Use case:** Review a plan before deciding whether to implement it, or build a plan in one session and implement in another.

---

## Files changed

| File | Change type |
|---|---|
| `skills/ship/SKILL.md` | Modify — Step 2 becomes a revision loop |
| `agents/planner.md` | Modify — replace single input section with three-case input handling |
| `agents/implementer.md` | Modify — add `Bash(make *)`, git commit per step, ambiguity rule, updated completion report |
| `skills/plan/SKILL.md` | Create — new thin `/plan` skill |

---

## Out of scope

- Changing model assignments (Opus for planner, Haiku for implementer)
- Adding a rollback/undo mechanism
- Multi-language test runner detection beyond `make`
- Changing the `plan.md` format
