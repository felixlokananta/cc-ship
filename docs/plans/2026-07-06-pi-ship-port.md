# Pi Port of /ship Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/ship` work in Pi with the same plan → review gate → delegated implementation → verify → PR workflow as the Claude Code skill.

**Architecture:** `/ship` becomes a Pi prompt template carrying the full orchestration (planning process embedded inline); a `subagent` extension (copied verbatim from Pi's bundled examples) delegates implementation to an `implementer` Pi agent definition; a `question` extension (also copied verbatim) provides structured clarifying questions. Source of truth is `cc-ship/pi/`, symlinked into `~/.pi/agent/` by `pi/install.sh`.

**Tech Stack:** Pi coding agent v0.80.x (`@earendil-works/pi-coding-agent`), Markdown prompt templates / agent definitions, bash install script. No new TypeScript is written — extension code is copied from the Pi package examples.

**Spec:** `docs/design/2026-07-06-pi-ship-port-design.md`

## Global Constraints

- All work happens in the `cc-ship` repo at `/Users/felixlokananta/PycharmProjects/cc-ship` (currently on `main`).
- The repo has unrelated dirty state (`install.sh` modified, stray `skills/*/​*` self-symlinks). **Never `git add -A` or `git add .`** — stage only the files each task names.
- The Pi package lives at `$(npm root -g)/@earendil-works/pi-coding-agent`. Copied extension files must be byte-identical to the examples (verify with `diff`).
- The implementer agent definition must NOT have a `model:` frontmatter key (it inherits the session default — explicit user decision).
- Plan file path used at runtime is `.pi/plan.md` (not `.claude/plan.md`).
- PRs created by the workflow target `develop`; attribution line is exactly: `🤖 Generated with pi via /ship`.
- Directory symlinks in install scripts must use `ln -sfn` (no-dereference). Plain `ln -sf` on an existing dir symlink nests a self-link — this is the bug visible as `skills/ship/ship` in this repo.

---

### Task 1: Scaffold `pi/` and copy the extension code verbatim

**Files:**
- Create: `pi/extensions/question.ts` (copy)
- Create: `pi/extensions/subagent/index.ts` (copy)
- Create: `pi/extensions/subagent/agents.ts` (copy)

**Interfaces:**
- Consumes: Pi package examples at `$(npm root -g)/@earendil-works/pi-coding-agent/examples/extensions/`.
- Produces: a `subagent` tool (params `{ agent, task }`, discovers agents from `~/.pi/agent/agents/*.md`) and a `question` tool (params `{ question, options: [{label, description?}] }`) once symlinked into `~/.pi/agent/extensions/` by Task 4. `pi/prompts/ship.md` (Task 3) refers to both tools by these names.

- [ ] **Step 1: Create directories and copy the files**

```bash
cd /Users/felixlokananta/PycharmProjects/cc-ship
PI_PKG="$(npm root -g)/@earendil-works/pi-coding-agent"
mkdir -p pi/prompts pi/agents pi/extensions/subagent
cp "$PI_PKG/examples/extensions/question.ts"        pi/extensions/question.ts
cp "$PI_PKG/examples/extensions/subagent/index.ts"  pi/extensions/subagent/index.ts
cp "$PI_PKG/examples/extensions/subagent/agents.ts" pi/extensions/subagent/agents.ts
```

- [ ] **Step 2: Verify the copies are byte-identical**

```bash
PI_PKG="$(npm root -g)/@earendil-works/pi-coding-agent"
diff "$PI_PKG/examples/extensions/question.ts"        pi/extensions/question.ts && \
diff "$PI_PKG/examples/extensions/subagent/index.ts"  pi/extensions/subagent/index.ts && \
diff "$PI_PKG/examples/extensions/subagent/agents.ts" pi/extensions/subagent/agents.ts && \
echo IDENTICAL
```

Expected output: `IDENTICAL` (no diff lines).

- [ ] **Step 3: Commit**

```bash
git add pi/extensions/question.ts pi/extensions/subagent/index.ts pi/extensions/subagent/agents.ts
git commit -m "feat(pi): vendor question and subagent extensions from pi examples"
```

---

### Task 2: Write the `implementer` agent definition

**Files:**
- Create: `pi/agents/implementer.md`

**Interfaces:**
- Consumes: `.pi/plan.md` at runtime (written by the `/ship` prompt in Task 3).
- Produces: agent named `implementer`, discoverable by the `subagent` tool from Task 1. Reports back with ✅/⚠️/🧪/📝 sections that the `/ship` prompt's verify step (Task 3) parses.

- [ ] **Step 1: Write `pi/agents/implementer.md` with exactly this content**

````markdown
---
name: implementer
description: Focused engineer that executes implementation plans from .pi/plan.md. Invoked after the plan has been approved. Does not re-plan or make architectural decisions — implements exactly what is specified.
tools: read, write, edit, bash
---

You are a focused software engineer. Your job is to implement exactly what is specified in `.pi/plan.md`. You do not re-plan, redesign, or make architectural decisions.

## Before you start

1. Read `.pi/plan.md` in full
2. Confirm you understand every step before touching any file
3. Check whether you are on an issue branch:
   - Run `git branch --show-current` to get the current branch name
   - If the branch name does not look like an issue branch (e.g. `main`, `master`, `develop`, or any branch not referencing the plan's issue or feature), create one:
     - Derive the branch name from the plan's **Source** field: if it contains a GitHub issue number (`#N`), use `issue-<N>-<slug>` where `<slug>` is a lowercase-hyphenated version of the issue title (max 5 words). If there is no issue number, use a short slug from the plan title.
     - Run `git checkout -b <branch-name>`
   - If already on an appropriate feature/issue branch, continue without switching

## Implementation rules

- Follow the plan step by step in order
- Match existing code style, naming conventions, and patterns in the codebase exactly
- If a step is ambiguous, stop and report the ambiguity in your final report rather than guessing
- Do not add features, refactor unrelated code, or make improvements not listed in the plan
- Write tests as specified in the plan's "Tests to write" section
- Only use bash for git, running tests/builds, and file inspection — never for destructive operations outside the repository

## After each step

1. Briefly note what was completed
2. Run the step's **Verification** check (if the plan specifies one) and confirm it passes before moving on
3. Check whether a Makefile exists: `find . -maxdepth 1 -name Makefile`
   - If yes, run `make test`
   - If tests **pass**: continue
   - If tests **fail**: diagnose the output, attempt a targeted fix, and re-run `make test`. Repeat up to **3 times**. Only stop and escalate if tests are still failing after 3 attempts — report what you tried and what the error is.
4. Stage and commit: `git add -A && git commit -m "step N: <description of what was done>"`
5. If a non-test blocker appears (missing dependency, ambiguous plan step, verification check fails after a targeted fix, etc.), stop immediately and report it

## When finished

Report back with:
- ✅ Steps completed
- ⚠️ Any blockers or deviations from the plan (and why)
- 🧪 Tests written and whether they pass (include `make test` output summary if applicable)
- 📝 Any follow-up items for the next session
````

- [ ] **Step 2: Verify frontmatter has no model key and the plan path is `.pi/plan.md`**

```bash
grep -c "^model:" pi/agents/implementer.md; grep -c ".claude/plan.md" pi/agents/implementer.md; grep -c ".pi/plan.md" pi/agents/implementer.md
```

Expected output: `0`, `0`, and a number ≥ 2 (grep exits 1 on the first two — that is the pass condition).

- [ ] **Step 3: Commit**

```bash
git add pi/agents/implementer.md
git commit -m "feat(pi): add implementer agent definition"
```

---

### Task 3: Write the `/ship` prompt template

**Files:**
- Create: `pi/prompts/ship.md`

**Interfaces:**
- Consumes: the `question` tool and the `subagent` tool (Task 1), the `implementer` agent (Task 2), `$@` argument expansion (Pi prompt-template syntax).
- Produces: the `/ship` command in any Pi session once symlinked (Task 4). Writes `.pi/plan.md` at runtime.

- [ ] **Step 1: Write `pi/prompts/ship.md` with exactly this content**

`````markdown
---
description: 'Plan-then-implement workflow — plan with clarifying questions, pause for human review, delegate to the implementer subagent, verify, open a PR. Accepts a feature description or a GitHub issue reference like "issue #12".'
argument-hint: '<feature description or "issue #N">'
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
`````

- [ ] **Step 2: Verify the adaptation points**

```bash
grep -c ".claude/plan.md" pi/prompts/ship.md; grep -c "AskUserQuestion" pi/prompts/ship.md; grep -c "Haiku" pi/prompts/ship.md
grep -c ".pi/plan.md" pi/prompts/ship.md
grep -n "Generated with pi via /ship" pi/prompts/ship.md
grep -n "argument-hint" pi/prompts/ship.md
```

Expected: the first three greps output `0` (exit code 1), `.pi/plan.md` count ≥ 6, and both `grep -n` lines find a match.

- [ ] **Step 3: Commit**

```bash
git add pi/prompts/ship.md
git commit -m "feat(pi): add /ship prompt template porting the plan-then-implement workflow"
```

---

### Task 4: Write `pi/install.sh`, run it, verify the install

**Files:**
- Create: `pi/install.sh` (mode 755)

**Interfaces:**
- Consumes: the files from Tasks 1–3 (paths relative to `pi/`).
- Produces: symlinks in `~/.pi/agent/{prompts,agents,extensions}`; removes the superseded `~/.pi/agent/extensions/ship.ts`.

- [ ] **Step 1: Write `pi/install.sh` with exactly this content**

```bash
#!/usr/bin/env bash
set -euo pipefail

PI_SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.pi/agent/prompts ~/.pi/agent/agents ~/.pi/agent/extensions

# Remove the superseded ship.ts extension — its /ship command collides with the prompt template
if [ -e ~/.pi/agent/extensions/ship.ts ] && [ ! -L ~/.pi/agent/extensions/ship.ts ]; then
  rm -f ~/.pi/agent/extensions/ship.ts
  echo "removed superseded ~/.pi/agent/extensions/ship.ts"
fi

ln -sf  "$PI_SRC_DIR/prompts/ship.md"        ~/.pi/agent/prompts/ship.md
ln -sf  "$PI_SRC_DIR/agents/implementer.md"  ~/.pi/agent/agents/implementer.md
ln -sf  "$PI_SRC_DIR/extensions/question.ts" ~/.pi/agent/extensions/question.ts
ln -sfn "$PI_SRC_DIR/extensions/subagent"    ~/.pi/agent/extensions/subagent

echo "cc-ship pi files installed from $PI_SRC_DIR"
```

Note the `-n` on the directory symlink: without it, a second run would create `subagent/subagent` inside the target.

- [ ] **Step 2: Make it executable and run it twice (idempotency check)**

```bash
chmod +x pi/install.sh
./pi/install.sh
./pi/install.sh
```

Expected: first run prints `removed superseded ~/.pi/agent/extensions/ship.ts` then `cc-ship pi files installed from …/cc-ship/pi`; second run prints only the installed line. No errors.

- [ ] **Step 3: Verify the resulting symlinks**

```bash
ls -la ~/.pi/agent/prompts/ship.md ~/.pi/agent/agents/implementer.md ~/.pi/agent/extensions/question.ts ~/.pi/agent/extensions/subagent
test ! -e ~/.pi/agent/extensions/ship.ts && echo SHIP_TS_GONE
test ! -e ~/.pi/agent/extensions/subagent/subagent && echo NO_NESTED_LINK
```

Expected: four symlinks pointing into `…/cc-ship/pi/…`, then `SHIP_TS_GONE`, then `NO_NESTED_LINK`.

- [ ] **Step 4: Commit**

```bash
git add pi/install.sh
git commit -m "feat(pi): add install script symlinking pi files into ~/.pi/agent"
```

---

### Task 5: Manual smoke test (human-in-the-loop)

**Files:** none (verification only).

**Interfaces:**
- Consumes: everything installed by Task 4.

This task cannot be fully automated — the `/ship` flow is interactive. Ask the user to run it, or run what is scriptable and hand the rest to the user as a checklist.

- [ ] **Step 1: Automated pre-flight — Pi loads the extensions without error**

```bash
cd "$(mktemp -d)" && git init -q scratch && cd scratch
pi --version
```

Expected: version prints (e.g. `0.80.3`) with no extension load errors. (Extension load failures surface at session start — the real check is Step 2.)

- [ ] **Step 2: Hand the user this checklist**

In a scratch git repo (no GitHub remote), run `pi` and verify:
1. Typing `/sh` autocompletes `/ship` with hint `<feature description or "issue #N">`.
2. `/ship add a hello.txt file containing "hello world"` — the agent analyzes, optionally asks a clarifying question **via the options-picker UI** (question tool), writes `.pi/plan.md`, presents it, and asks "Does this plan look correct?".
3. Reply `yes` — the `subagent` tool is invoked with the `implementer` agent (visible in the TUI with streaming output), steps get committed.
4. PR step is **skipped gracefully** with a note (no remote).
5. In a repo with a GitHub remote: `/ship issue #N` fetches the issue via `gh issue view` and the eventual PR body ends with `🤖 Generated with pi via /ship`.

- [ ] **Step 3: Record outcome**

If anything fails, fix forward in the relevant file (Tasks 1–4 own the files) and re-run the failing checklist item. When the checklist passes, the plan is done.
