# Design: /brainstorm skill + @issue-creator agent

## Summary

Add a `/brainstorm` skill and `@issue-creator` agent to cc-ship. The brainstorm skill
runs an interactive Opus dialogue to explore a feature idea, produces a structured
summary (split into multiple issues if the feature is too large), then optionally
delegates to `@issue-creator` (Haiku) to file the issues on GitHub. This sits upstream
of the existing `/ship` workflow — brainstorm first, implement later.

## Architecture

Two new files, plus an update to `install.sh`:

| File | Role | Model |
|------|------|-------|
| `skills/brainstorm/SKILL.md` | `/brainstorm` — dialogue, structured summary, delegates to `@issue-creator` | Opus (inherits) |
| `agents/issue-creator.md` | `@issue-creator` — repo detection, `gh issue create` | Haiku |
| `install.sh` | Two new symlinks | — |

### Overall workflow

```
/brainstorm <idea>
  → dialogue → structured summary → confirm → @issue-creator → issue URLs
                                                      ↓
                                              /ship #N  (existing flow)
```

## `/brainstorm` skill — conversation flow

1. **Open** — acknowledge the idea, ask the first clarifying question
2. **Dialogue** — one question at a time: problem, audience, constraints, success criteria
3. **Scope check** — after the picture is clear, assess if the feature is too large for one issue
   - If yes: decompose into 2–5 focused sub-issues, present the split, let the user adjust
   - If no: proceed with a single issue
4. **Draft summary** — present the structured summary (see format below), ask "Does this capture it correctly?"
5. **Revise loop** — update and re-present until the user confirms
6. **Issue prompt** — ask "Create a GitHub issue from this?"
   - Yes → delegate to `@issue-creator` with the full summary
   - No → print the summary for manual copy

The skill accepts an optional argument (`/brainstorm <idea>`) but also works with no
argument — it opens with "What's the idea?"

## Structured summary format

### Single issue

```markdown
## Title
<one-line feature title>

## Problem
<what's broken or missing, and why it matters>

## Proposed solution
<what will be built — concrete, not vague>

## Acceptance criteria
- [ ] <specific, testable condition>
- [ ] <specific, testable condition>

## Implementation order
Issue 1 of 1 — standalone.

## Out of scope
<what this explicitly does NOT cover>

## Labels
<comma-separated labels, e.g. enhancement, feature — omit if none>
```

### Multi-issue (feature too large for one issue)

Each block uses the same structure. Blocks are numbered and sequenced:

```markdown
## Issue 1 of 3: <title>  ← start here

**Problem:** ...
**Proposed solution:** ...
**Acceptance criteria:**
- [ ] ...
**Implementation order:** Issue 1 of 3 — start here.
**Out of scope:** ...
**Labels:** ...

---

## Issue 2 of 3: <title>  ← implement after Issue 1

**Problem:** ...
**Proposed solution:** ...
**Acceptance criteria:**
- [ ] ...
**Implementation order:** Issue 2 of 3 — implement after **<Issue 1 title>** is merged.
**Out of scope:** ...
**Labels:** ...

---

## Issue 3 of 3: <title>  ← implement last

...
**Implementation order:** Issue 3 of 3 — implement after **<Issue 2 title>** is merged.
...
```

The "Implementation order" section appears in each GitHub issue body so the sequence
is visible on GitHub without cross-referencing.

## `@issue-creator` agent

Model: Haiku. Tool allowlist: `Bash(git remote get-url origin)`, `Bash(find *)`,
`Bash(gh issue create *)`.

### Repo detection (in order)

1. `git remote get-url origin` in CWD — if it returns a URL, use that repo
2. If CWD is not a git repo: `find . -maxdepth 2 -name .git -type d`
3. One sub-repo found → use it automatically
4. Multiple sub-repos found → present numbered list, ask user to pick
5. None found → ask user for `owner/name`

### Issue filing

- Iterates through each issue block in order (1 → 2 → 3)
- For each: `gh issue create --title "..." --body "..." [--label "..."]`
- Prints the issue URL after each creation before moving to the next
- If `gh` is unavailable or not authenticated: prints each issue body formatted
  for manual copy-paste

## `install.sh` changes

```bash
ln -sf "$REPO_DIR/agents/issue-creator.md" ~/.claude/agents/issue-creator.md
ln -sf "$REPO_DIR/skills/brainstorm"        ~/.claude/skills/brainstorm
```

## Out of scope

- Parent/epic issue linking between the split sub-issues
- GitHub Projects or milestone assignment
- Automatic linking back from `/ship` to the brainstorm session
- Editing or closing existing issues
