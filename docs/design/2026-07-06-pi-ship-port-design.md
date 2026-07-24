# Pi Port of `/ship` — Design

**Date:** 2026-07-06
**Status:** Approved

## Goal

Replicate the Claude Code `/ship` skill (plan-then-implement workflow) as a Pi
coding-agent extension set, so that typing `/ship <feature or issue #N>` in a
Pi session runs the same six-step orchestration: plan → human review gate →
delegated implementation → goal verification → PR creation → summary.

## Background

- The Claude Code version lives in this repo: `skills/ship/SKILL.md`
  (orchestration), `docs/planning-process.md` (canonical planning process),
  and `agents/implementer.md` (restricted implementer subagent).
- Pi (`@earendil-works/pi-coding-agent`, v0.80.x) provides equivalent
  primitives: **prompt templates** (`~/.pi/agent/prompts/*.md`, invoked as
  `/name`), **agent definitions** (`~/.pi/agent/agents/*.md` consumed by the
  bundled `subagent` example extension), and **custom tools** (the bundled
  `question` example provides an AskUserQuestion-style options picker).
- The user's existing `~/.pi/agent/extensions/ship.ts` implements a different,
  simpler workflow (branch + PR stub + "go implement") and is superseded.

## Decisions

1. **Architecture: prompt template + subagent extension** (not a hand-rolled
   TypeScript orchestrator). The `/ship` prompt template carries the
   orchestration instructions; the `subagent` tool performs delegation; the
   implementer is a Pi agent definition. Minimal TypeScript to maintain, and
   the workflow text stays close to the Claude Code original.
2. **Implementer model: session default.** The agent definition omits the
   `model` frontmatter field, so the spawned `pi` subprocess inherits the
   user's default model. (The Claude Code version pins Haiku; the user
   explicitly chose not to pin a model here.)
3. **Source of truth: `cc-ship/pi/`**, symlinked into `~/.pi/agent/` by an
   install script — the same pattern already used for the Claude Code skills
   (symlinked into `~/.claude/skills/`).
4. **Clarifying questions use the `question` tool** (ported from Pi's
   examples), giving the same structured pick-an-option UX as
   AskUserQuestion. The tool asks one question per call.
5. **The existing `~/.pi/agent/extensions/ship.ts` is deleted** — its
   registered `/ship` command would collide with the new prompt template.

## Layout

```
cc-ship/pi/
├── prompts/
│   └── ship.md              → ~/.pi/agent/prompts/ship.md
├── agents/
│   └── implementer.md       → ~/.pi/agent/agents/implementer.md
├── extensions/
│   ├── question.ts          → ~/.pi/agent/extensions/question.ts
│   └── subagent/            → ~/.pi/agent/extensions/subagent/
│       ├── index.ts
│       └── agents.ts
└── install.sh               # creates the symlinks; removes stale ship.ts
```

## Components

### `pi/prompts/ship.md`

Direct port of `skills/ship/SKILL.md` with the full planning process from
`docs/planning-process.md` **embedded inline** (a Pi session has no guarantee
the cc-ship docs exist in the working project, so the template is
self-contained). Frontmatter: `description` and `argument-hint`. Arguments via
`$@`.

The six steps, adapted:

1. **Plan** — detect input type (feature text / `#N` issue via
   `gh issue view <N> --comments` / vague keyword via `gh issue list`),
   analyze the codebase read-only, ask clarifying questions with the
   `question` tool (one per call, 2–4 concrete options each), run the
   completeness check, write the plan to **`.pi/plan.md`** in the fixed
   format (Source, Summary, Goal, Affected files, Implementation steps with
   Verification per step, Tests to write, Risks and gotchas, Out of scope).
2. **Review** — present the plan in full; do not proceed until the user
   explicitly says `yes`; revise-and-re-present loop on feedback.
3. **Implement** — call the `subagent` tool with `{ agent: "implementer",
   task: ... }`; the implementer reads `.pi/plan.md` and executes it.
4. **Verify goal** — compare the implementer's report against the plan's
   `## Goal`; re-delegate with a gap description until satisfied or blocked.
5. **Create PR** — `git push -u origin HEAD`, then `gh pr create --base
   develop` with title from the plan Summary and the same body template
   (Summary / Changes / Tests / Follow-up). Attribution line reads
   "🤖 Generated with pi via /ship". Skip gracefully when `gh` or a remote
   is unavailable.
6. **Done** — summary: PR URL, what was implemented, tests, follow-ups.

### `pi/agents/implementer.md`

Port of `agents/implementer.md`:

- Frontmatter: `name: implementer`, `description`, `tools: read, write,
  edit, bash` — **no `model` field** (inherits session default).
- Same system prompt rules: read `.pi/plan.md` in full first; ensure an
  issue/feature branch (create `issue-<N>-<slug>` from the plan's Source if
  needed); follow steps in order; match existing code style; no re-planning
  or unrequested refactors; run each step's Verification; run `make test`
  when a Makefile exists with up to 3 diagnose-and-fix attempts; commit per
  step (`step N: <description>`); stop and report on non-test blockers.
- Same structured report: ✅ steps completed, ⚠️ blockers/deviations,
  🧪 tests and results, 📝 follow-ups.
- Tool restriction note: Pi's tool set is coarser than Claude Code's
  `Bash(git *)` allowlist patterns; `bash` must be granted for git/tests, so
  behavioral restriction is enforced by the system prompt rules instead.

### `pi/extensions/question.ts` and `pi/extensions/subagent/`

Copied **verbatim** from the Pi package examples
(`examples/extensions/question.ts`, `examples/extensions/subagent/{index.ts,
agents.ts}`). They import only `@earendil-works/pi-coding-agent` and
`@earendil-works/pi-tui`, both available to extensions. The subagent
extension's sample agents/prompts are not copied — only the extension code.

### `pi/install.sh`

Mirrors the repo's existing `install.sh` style: creates
`~/.pi/agent/{prompts,agents,extensions}` as needed, symlinks the four
targets, removes the superseded `~/.pi/agent/extensions/ship.ts` (with a
notice), and prints what it did. Idempotent (`ln -sf`).

## Error handling

- Missing `gh`/remote at PR time → skip PR creation, note it in the summary
  (same as Claude Code version).
- Subagent failure / blocker report → surfaced to the user by the verify
  loop in step 4; the orchestrator never silently retries more than the
  goal-gap re-delegation described above.
- `question` tool cancelled (Escape) → the agent proceeds by asking in plain
  text (tool returns a cancellation the model can see).

## Testing

Manual verification (this is workflow tooling, not product code):

1. `pi/install.sh` run is idempotent and produces the four symlinks; old
   `ship.ts` gone.
2. In a Pi session in a scratch git repo: `/ship add a hello command` walks
   the full flow — clarifying question appears via the options UI, plan
   written to `.pi/plan.md`, gate waits for `yes`, subagent tool invoked,
   PR step skipped gracefully without a remote.
3. In a repo with a GitHub remote: `/ship issue #N` fetches the issue and
   the PR body follows the template.

## Out of scope

- Porting `/shipplan` and `/brainstorm` (same pattern; can follow later).
- Pinning the implementer to a cheaper model.
- Programmatic (code-enforced) review gate.
- Publishing the Pi files as a Pi package (`pi.prompts` manifest); symlinks
  suffice for now.
