# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`cc-ship` is a Claude Code skill that implements a **plan-then-implement** workflow using two subagents. It is not a runnable application — it is a configuration artifact (Markdown files) installed by symlinking into `~/.claude/`.

## Architecture

Four files do all the work:

| File | Role | Model |
|------|------|-------|
| `skills/ship/SKILL.md` | `/ship` — plan + review loop + implement | (inherits) |
| `skills/shipplan/SKILL.md` | `/shipplan` — plan + review only, no implementation | (inherits) |
| `agents/planner.md` | `@planner` — reads codebase, fetches GitHub issues, writes `.claude/plan.md` | Opus |
| `agents/implementer.md` | `@implementer` — executes `.claude/plan.md` step by step, commits per step | Haiku |

**`/ship` data flow:** `/ship <request>` → `@planner` writes `.claude/plan.md` → user reviews (can iterate) → `@implementer` executes → `/ship` summarises.

**`/shipplan` data flow:** `/shipplan <request>` → `@planner` writes `.claude/plan.md` → presents plan to user → stops. Run `/ship` when ready to implement.

Each agent runs in its own context window so planning context never bleeds into implementation.

## Install / update

```bash
# Install (first time)
git clone https://github.com/YOUR_HANDLE/cc-ship.git ~/.claude/cc-ship
mkdir -p ~/.claude/agents ~/.claude/skills
ln -s ~/.claude/cc-ship/agents/planner.md ~/.claude/agents/planner.md
ln -s ~/.claude/cc-ship/agents/implementer.md ~/.claude/agents/implementer.md
ln -s ~/.claude/cc-ship/skills/ship ~/.claude/skills/ship
ln -s ~/.claude/cc-ship/skills/shipplan ~/.claude/skills/shipplan

# Update
cd ~/.claude/cc-ship && git pull
```

Symlinks mean `git pull` propagates changes instantly — no re-linking required.

## Key design constraints

- **Planner is read-only.** Its tool allowlist is scoped to: `Read`, `Grep`, `Glob`, `Bash(gh issue view *)`, `Bash(gh issue list *)`, `Bash(gh issue view * --comments)`, `Bash(git log *)`, `Bash(git diff *)`, `Bash(find *)`, `Bash(cat *)`. No write tools. The `git log` and `git diff` grants let it read change history and diffs, not just current file state.
- **Implementer is write-restricted.** Its Bash allowlist is `git *`, `find *`, `cat *`, `mkdir *`, `mv *`, `cp *`, `make *` — no arbitrary shell. It must execute the plan verbatim without re-planning or redesigning.
- **Plan format is fixed.** `.claude/plan.md` must use the exact structure defined in `agents/planner.md` (Source, Summary, Affected files, Implementation steps, Tests to write, Risks and gotchas, Out of scope). Do not change this format without updating both the planner and the skill.
- **Human review is a revision loop.** `/ship` and `/shipplan` both present the plan and wait for explicit `yes`. If the user describes changes, the skill re-delegates to `@planner` with the original request + feedback — revisions go through full codebase analysis, not free-form edits. Implementation never starts without an explicit `yes`.

## Agent behaviors

### Planner
- Detects input type before doing anything: plain text → codebase analysis directly; `#N` → `gh issue view <N> --comments` then analysis; vague keyword → `gh issue list` to find the issue, confirm if ambiguous, then proceed as issue number.
- Codebase analysis covers: directly affected files, indirectly affected files (imports, tests, migrations, config), existing patterns to match, and gotchas/risks.
- Stops immediately after writing `.claude/plan.md` and confirms to the user. Does not continue past that point.

### Implementer
- **Pre-flight:** reads `.claude/plan.md` in full and confirms understanding of every step before touching any file.
- **Ambiguity rule:** if a step is unclear, stops and asks rather than guessing.
- **After each step:** checks for a Makefile (`find . -maxdepth 1 -name Makefile`), runs `make test` if present, then commits with `git add -A && git commit -m "step N: <description>"`. Stops immediately if tests fail or a blocker appears.
- **Completion report format:**
  - ✅ Steps completed
  - ⚠️ Blockers or deviations from the plan (and why)
  - 🧪 Tests written and whether they pass (includes `make test` output summary)
  - 📝 Follow-up items for the next session

## Plan output location

The planner always writes to `.claude/plan.md` **in the user's project**, not in this repo. That file is project-specific and ephemeral; it can be committed for a record but is not part of `cc-ship` itself.

## Requirements in the target environment

- Claude Code v2.1+
- GitHub CLI (`gh`) with `gh auth login` completed — only required when using `issue #N` references
