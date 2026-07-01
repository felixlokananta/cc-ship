# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`cc-ship` is a Claude Code skill that implements a **plan-then-implement** workflow. Planning runs in the main agent (including live clarifying questions); implementation is delegated to a subagent. It is not a runnable application — it is a configuration artifact (Markdown files) installed by symlinking into `~/.claude/`.

## Architecture

Six files do all the work:

| File | Role | Model |
|------|------|-------|
| `skills/brainstorm/SKILL.md` | `/brainstorm` — interactive dialogue, structured summary, delegates to `@issue-creator` | (inherits) |
| `skills/ship/SKILL.md` | `/ship` — plan + review loop + implement | (inherits) |
| `skills/shipplan/SKILL.md` | `/shipplan` — plan + review only, no implementation | (inherits) |
| `docs/planning-process.md` | Canonical planning process (reference doc, followed by the main agent in `/ship` and `/shipplan`) | (not an agent) |
| `agents/implementer.md` | `@implementer` — executes `.claude/plan.md` step by step, commits per step | Haiku |
| `agents/issue-creator.md` | `@issue-creator` — detects repo, files GitHub issues from brainstorm summary | Haiku |

**`/brainstorm` data flow:** `/brainstorm <idea>` → dialogue → structured summary → user confirms → `@issue-creator` files GitHub issues.

**`/ship` data flow:** `/ship <request>` → main agent plans (writes `.claude/plan.md`) → user reviews (can iterate) → main agent re-plans if needed → `@implementer` executes → `/ship` summarises.

**`/shipplan` data flow:** `/shipplan <request>` → main agent plans (writes `.claude/plan.md`) → presents plan to user → stops. Run `/ship` when ready to implement.

Only implementation is isolated: the implementer reads `.claude/plan.md` fresh in its own context. Planning runs in the main agent and can include conversation history and live clarifying questions via `AskUserQuestion`.

## Install / update

```bash
# Install (first time)
git clone https://github.com/YOUR_HANDLE/cc-ship.git ~/.claude/cc-ship
bash ~/.claude/cc-ship/install.sh

# Update
cd ~/.claude/cc-ship && git pull
```

Symlinks mean `git pull` propagates changes instantly — no re-running the script required.

## Key design constraints

- **Planning is read-only by convention.** During planning, the main agent follows the discipline documented in `docs/planning-process.md`: only read the codebase and history via `Read`, `Grep`, `Glob`, and read-only `gh`/`git` commands. Do not modify files except to write `.claude/plan.md`. (Note: this is convention, not tool enforcement — the main agent has write tools.)
- **Implementer is write-restricted.** Its Bash allowlist is `git *`, `find *`, `cat *`, `mkdir *`, `mv *`, `cp *`, `make *` — no arbitrary shell. It must execute the plan verbatim without re-planning or redesigning.
- **Plan format is fixed.** `.claude/plan.md` must use the exact structure defined in `docs/planning-process.md` (Source, Summary, Goal, Affected files, Implementation steps, Tests to write, Risks and gotchas, Out of scope). Do not change this format without updating both the planning process and the skills.
- **Human review is a revision loop.** `/ship` and `/shipplan` both present the plan and wait for explicit `yes`. If the user describes changes, the main agent re-runs the planning phase with the original request + feedback — revisions go through full codebase analysis, not free-form edits. Implementation never starts without an explicit `yes`.

## Agent behaviors

### Planning phase
- Runs in the main agent context (not a subagent) to enable live clarifying questions via `AskUserQuestion`.
- Detects input type before doing anything: plain text → codebase analysis directly; `#N` → `gh issue view <N> --comments` then analysis; vague keyword → `gh issue list` to find the issue, confirm if ambiguous, then proceed as issue number.
- Codebase analysis covers: directly affected files, indirectly affected files (imports, tests, migrations, config), existing patterns to match, and gotchas/risks.
- Asks clarifying questions via `AskUserQuestion` when ambiguous, offering 2–4 concrete options derived from codebase findings.
- Writes `.claude/plan.md` in the fixed format and stops. Does not continue past that point. The main agent confirms the plan is ready for review.

### Implementer
- **Pre-flight:** reads `.claude/plan.md` in full and confirms understanding of every step before touching any file.
- **Ambiguity rule:** if a step is unclear, stops and asks rather than guessing.
- **After each step:** checks for a Makefile (`find . -maxdepth 1 -name Makefile`), runs `make test` if present, then commits with `git add -A && git commit -m "step N: <description>"`. Stops immediately if tests fail or a blocker appears.
- **Completion report format:**
  - ✅ Steps completed
  - ⚠️ Blockers or deviations from the plan (and why)
  - 🧪 Tests written and whether they pass (includes `make test` output summary)
  - 📝 Follow-up items for the next session

### Issue creator
- **Tool allowlist:** `Bash(git remote *)`, `Bash(find *)`, `Bash(gh issue create *)` — read-only git access (remote URL detection only), no write access to git history.
- **Repo detection order:** `git remote get-url origin` in CWD → `find . -maxdepth 2 -name .git -type d` for sub-repos → ask user for `owner/repo`.
- **Parse-then-file loop:** parses the full Markdown summary into issue blocks (one per `## Title` or `## Issue N of M:` header), then files them in order via `gh issue create --repo`.
- **Error handling:** stops immediately if `gh issue create` exits non-zero; reports partial success and offers to retry remaining issues.
- **gh fallback:** if `gh` is unavailable or unauthenticated, prints each issue body formatted for manual copy-paste instead of failing silently.

## Plan output location

The planner always writes to `.claude/plan.md` **in the user's project**, not in this repo. That file is project-specific and ephemeral; it can be committed for a record but is not part of `cc-ship` itself.

## Requirements in the target environment

- Claude Code v2.1+
- GitHub CLI (`gh`) with `gh auth login` completed — required when using `issue #N` references with `/ship`/`/shipplan`, and when confirming issue creation at the end of `/brainstorm`
