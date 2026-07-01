# Plan: Move planning into the main agent; relocate planner.md to docs/planning-process.md

## Source
GitHub issue #4 — "Move planning into the main agent so the planner can ask clarifying questions live"
https://github.com/felixlokananta/cc-ship/issues/4
Revision note from user: use `docs/planning-process.md` as the new location for the relocated planner reference document (not `reference/planner.md`, not `agents/planner.md`). Keep everything else from the prior revision.

## Summary
Today `/ship` and `/shipplan` delegate planning to the `@planner` subagent. Subagents run in an isolated context and cannot surface `AskUserQuestion` prompts to the user, so the planner's clarifying-question step silently fails. This plan moves the entire planning phase (input-type detection, GitHub issue fetching, codebase analysis, clarifying questions, and writing `.claude/plan.md`) into the main agent driven by the two skills, and converts `agents/planner.md` into a non-installed reference document at `docs/planning-process.md`. Implementation stays isolated: after approval, `/ship` still delegates to the `@implementer` subagent, which reads `.claude/plan.md` fresh.

## Goal
Running `/ship` or `/shipplan` performs the full planning phase in the main agent — including clarifying questions that appear to the user via `AskUserQuestion` — writes `.claude/plan.md` in the existing fixed format, and (for `/ship`) only then delegates to the `@implementer` subagent; `@planner` is no longer invoked as a subagent for planning, and the planning process reference lives at `docs/planning-process.md`.

## Affected files
- `docs/planning-process.md` — **create** (moved from `agents/planner.md`); becomes the canonical planning-process reference, frontmatter stripped, read-only discipline preserved as prose. The `docs/` folder already exists (contains `docs/design/`).
- `agents/planner.md` — **delete** (moved via `git mv`; content relocated to `docs/planning-process.md`).
- `skills/ship/SKILL.md` — **modify**: replace "delegate to @planner" Step 1 with an inline planning phase run by the main agent that follows `docs/planning-process.md`; update the revision loop to re-run planning in the main agent; update frontmatter description.
- `skills/shipplan/SKILL.md` — **modify**: same inline planning phase following `docs/planning-process.md`; update frontmatter description; keep the "stop after presenting" behavior.
- `install.sh` — **modify**: remove the `planner.md` symlink line; add a guarded cleanup that removes a stale `~/.claude/agents/planner.md` symlink from prior installs.
- `CLAUDE.md` — **modify**: update architecture table, data-flow descriptions, and design-constraint text to reflect that planning runs in the main agent and the process is documented at `docs/planning-process.md`.
- `README.md` — **modify**: update the "How it works" diagram, the Structure tree, and the keyword-usage comment so `@planner` is no longer shown as a subagent step.
- `CONTRIBUTING.md` — **modify**: update the "Planner behaviour → agents/planner.md" pointer to `docs/planning-process.md`.
- `SECURITY.md` — **modify**: reword the prompt-injection sentence so it no longer implies `@planner` is a subagent that "takes actions" (planning now runs in the main agent with read-only discipline by convention).
- `.github/ISSUE_TEMPLATE/bug_report.md` and `.github/ISSUE_TEMPLATE/feature_request.md` — **modify**: change `@planner` mentions to "the planning phase" for accuracy.

## Implementation steps

### Step 1: Relocate planner.md to docs/planning-process.md
**File:** `docs/planning-process.md` (new), `agents/planner.md` (removed)
**What:** `git mv agents/planner.md docs/planning-process.md`. Then edit the moved file: remove the YAML frontmatter block (the `name`, `description`, `model`, `tools` lines between the `---` fences). Replace it with a short intro paragraph, e.g.: "This document defines the canonical planning process the main agent follows when running `/ship` and `/shipplan`. It is a reference document — not an installed subagent." Keep all existing sections (Understanding the request, Codebase analysis, Clarifying questions, Output format) verbatim.
**Why:** The planner is no longer a subagent, so the `agents/` location and agent frontmatter are misleading. The user asked for this content to live at `docs/planning-process.md`.
**Details:** Preserve the exact plan.md output format block (Source, Summary, Goal, Affected files, Implementation steps, Tests to write, Risks and gotchas, Out of scope) unchanged — the skills and `@implementer` depend on it. Add one prose line codifying the read-only discipline that the frontmatter tool allowlist used to enforce: "Discipline: during planning, only read the codebase and history (Read, Grep, Glob, and read-only `gh`/`git` commands). Do not modify files except to write `.claude/plan.md`."

### Step 2: Inline the planning phase into /ship
**File:** `skills/ship/SKILL.md`
**What:** Replace "Step 1 — Plan" (currently "Delegate to @planner ...") with a step that instructs the main agent to run the planning process itself, following `docs/planning-process.md`. The step must cover: detect input type (description / `#N` issue / keyword), fetch the issue via `gh issue view <N> --comments` when referenced, analyse the codebase, ask clarifying questions via `AskUserQuestion` when the request is ambiguous (per the criteria in `docs/planning-process.md`), then write `.claude/plan.md` in the fixed format. Update the revision loop (current Step 2's "Re-delegate to @planner"): instead of re-delegating, the main agent re-runs the planning process itself with the original request plus the user's feedback and rewrites `.claude/plan.md`.
**Why:** `AskUserQuestion` only works in the main agent context; running planning there makes clarifying questions reach the user.
**Details:** Keep Steps 3–6 (Implement via `@implementer`, Verify goal, Create PR, Done) unchanged — implementation isolation is out of scope per the issue. Update the frontmatter `description` to drop "Uses Opus (@planner)" phrasing and instead say the main agent plans (following `docs/planning-process.md`) and delegates implementation to `@implementer` (Haiku). Ensure the skill still explicitly waits for a `yes` before Step 3.

### Step 3: Inline the planning phase into /shipplan
**File:** `skills/shipplan/SKILL.md`
**What:** Replace "Step 1 — Plan" (delegate to @planner) with the same inline planning-phase instructions as Step 2 above (input-type detection, issue fetching, codebase analysis, `AskUserQuestion` clarifying questions, write `.claude/plan.md`), following `docs/planning-process.md`. Keep "Step 2 — Present" and the stop-after-presenting behavior unchanged.
**Why:** `/shipplan` must have identical live clarifying-question behavior per acceptance criteria, then stop.
**Details:** Update the frontmatter `description` to remove "Uses @planner (Opus)" and describe the main-agent planning that follows `docs/planning-process.md`. Do not add implementation steps — `/shipplan` still stops after presenting.

### Step 4: Remove the planner symlink from install.sh
**File:** `install.sh`
**What:** Delete the line `ln -sf "$REPO_DIR/agents/planner.md" ~/.claude/agents/planner.md`. Leave the `implementer.md` and `issue-creator.md` symlinks and all skill symlinks intact.
**Why:** planner.md is no longer an installed subagent; installing it would leave a stale `@planner` agent that contradicts the new flow.
**Details:** Add a comment noting the planning process now lives in `docs/planning-process.md` and is followed by the skills. Add a cleanup line before the remaining `ln` calls to remove a previously-installed stale symlink, guarded so it only removes a symlink and not a real file, e.g. `[ -L ~/.claude/agents/planner.md ] && rm -f ~/.claude/agents/planner.md`, so existing installs are cleaned on next run.

### Step 5: Update CLAUDE.md architecture and constraints
**File:** `CLAUDE.md`
**What:** (a) In the architecture table, change the planner row: it is now `docs/planning-process.md` and no longer a subagent/Model entry — describe it as the "canonical planning process (reference doc, followed by the main agent)". (b) Update the "/ship data flow" and "/shipplan data flow" lines to show the main agent planning (writes `.claude/plan.md`) rather than "@planner writes". (c) Update "Key design constraints": the "Planner is read-only" bullet becomes a convention the main agent follows during planning (no tool allowlist enforcement); the "Human review is a revision loop" bullet changes "re-delegates to @planner" to "the main agent re-runs the planning process". Update the "Plan format is fixed" bullet's `agents/planner.md` reference to `docs/planning-process.md`. (d) Update the "Agent behaviors → Planner" subsection to "Planning phase" and note it runs in the main agent. (e) Update the opening "using two subagents" framing and "Six files do all the work" intro as needed — planner.md still exists, just relocated, so the count stays six but the planner is a reference not an agent.
**Why:** CLAUDE.md is the source of truth for contributors and must match the new flow (explicit acceptance criterion).
**Details:** Keep the plan.md format description and `@implementer` / `@issue-creator` sections unchanged. Update every `agents/planner.md` path reference to `docs/planning-process.md`.

### Step 6: Update README diagram, structure tree, and usage text
**File:** `README.md`
**What:** In the "How it works" ASCII diagram (around lines 49–61), replace the `@planner (Opus)` box with a "planning phase (main agent, follows docs/planning-process.md)" box, and change "(request changes → @planner revises)" to "(request changes → main agent re-plans)". Update the "Each agent runs in its own context window — planning context never bleeds into implementation" line (line 74) to reflect that only implementation is isolated now (planning runs in the main agent; the implementer still reads plan.md fresh). Update the usage comment "# Plan + implement from a keyword (planner searches open issues)" (line 115) to "(searches open issues)". In the Structure tree (around lines 127–140), remove the `planner.md` line from under `agents/` and add a `docs/` entry with `planning-process.md`.
**Why:** Keep user-facing docs accurate.
**Details:** Documentation only; no behavior depends on this.

### Step 7: Update remaining references (CONTRIBUTING, SECURITY, issue templates)
**File:** `CONTRIBUTING.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/bug_report.md`, `.github/ISSUE_TEMPLATE/feature_request.md`
**What:** In `CONTRIBUTING.md` (line 22), change "Planner behaviour → `agents/planner.md`" to "Planning behaviour → `docs/planning-process.md`". In `SECURITY.md` (line 5), reword the sentence so prompt-injection risk applies to "the planning phase or `@implementer`" rather than "`@planner` or `@implementer`". In `bug_report.md` (lines 3, 10) and `feature_request.md` (line 3), change `@planner` mentions to "the planning phase" for accuracy.
**Why:** Eliminate stale `@planner`-as-subagent references repo-wide.
**Details:** Pure text edits.

## Tests to write
This repo has no automated test suite (it is a prompt/config artifact; no Makefile). Verification is manual:
- `bash install.sh` runs cleanly and does NOT create `~/.claude/agents/planner.md`; `implementer.md` and `issue-creator.md` symlinks still created; a pre-existing stale `planner.md` symlink is removed.
- `grep -rn "@planner" .` (excluding `.git` and this plan) returns only intentional historical/wording references — no skill still delegates to `@planner`.
- `grep -rn "agents/planner.md" .` returns nothing (all pointers updated to `docs/planning-process.md`).
- `grep -rn "reference/planner.md" .` returns nothing (the earlier revision's target is not used).
- Dry-run walkthrough: confirm `/ship` and `/shipplan` SKILL.md instruct the main agent to run planning inline (following `docs/planning-process.md`) and to call `AskUserQuestion` for ambiguous requests, then write `.claude/plan.md`.
- Confirm `/ship` still delegates Step 3 to `@implementer` and waits for an explicit `yes` before doing so.
- Confirm the `.claude/plan.md` format block in `docs/planning-process.md` is unchanged (Source, Summary, Goal, Affected files, Implementation steps, Tests to write, Risks and gotchas, Out of scope).

## Risks and gotchas
- **Stale installed symlink:** users who already ran the old `install.sh` have `~/.claude/agents/planner.md` symlinked. Removing the repo file leaves a dangling symlink and a lingering `@planner` agent until they re-run install. Mitigation: the guarded `rm -f` of the symlink added in Step 4.
- **Loss of tool-allowlist enforcement:** the read-only discipline was previously enforced by the subagent's `tools` allowlist. In the main agent, planning read-only behavior is now convention only — the main agent has write tools. Mitigation: state the discipline explicitly in `docs/planning-process.md` and in the skills. Accepted tradeoff per the issue.
- **Context bleed:** planning now shares context with whatever the user was doing in the main session. Implementation isolation is preserved (implementer reads plan.md fresh), so this only affects planning quality, not implementation cleanliness.
- **No breaking changes to plan.md format or `@implementer`** — both are explicitly out of scope, keeping the change contained.

## Out of scope
- Any change to `@implementer`'s behavior or tool allowlist.
- Any change to `/brainstorm` or `@issue-creator`.
- New or renamed fields in the `.claude/plan.md` format.
- Adding automated tests / CI (repo has none today).
- Changing which model performs planning (model selection no longer applies once planning runs in the main agent).
