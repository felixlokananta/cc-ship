# cc-ship Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the cc-ship workflow with a correct plan revision loop, explicit planner input handling, implementer git/test discipline, and a new `/shipplan` skill.

**Architecture:** Four markdown configuration files are modified or created — no runnable code. Changes are self-contained edits to existing frontmatter and instruction sections in each agent/skill file.

**Tech Stack:** Claude Code agents and skills (Markdown), GitHub CLI (`gh`), GNU Make

---

## File Map

| File | Change |
|---|---|
| `skills/ship/SKILL.md` | Replace Step 2 with a revision loop that re-delegates to `@planner` |
| `agents/planner.md` | Replace single input section with three-case input routing |
| `agents/implementer.md` | Add `Bash(make *)` to tools; add git commit + test step after each step; update completion report |
| `skills/shipplan/SKILL.md` | Create new file — thin `/shipplan` skill |

---

## Task 1: Fix the plan revision loop in `/ship`

**Files:**
- Modify: `skills/ship/SKILL.md`

The current Step 2 says "I'll update the plan before implementing" but has no instructions to re-invoke `@planner`. The revision loop must explicitly re-delegate to `@planner` so revisions go through codebase analysis, not free-form edits.

- [ ] **Step 1: Open `skills/ship/SKILL.md` and read the current Step 2**

```bash
cat skills/ship/SKILL.md
```

Expected: Step 2 currently has a single prompt asking the user yes/no with no loop.

- [ ] **Step 2: Replace Step 2 with the revision loop**

Replace the `## Step 2 — Review` section with:

```markdown
## Step 2 — Review

Read `.claude/plan.md` and present it to the user in full.

Then ask:

> **Does this plan look correct?**
> - Reply `yes` to proceed with implementation
> - Describe any changes needed and the plan will be revised before implementing

Do not proceed to Step 3 until the user explicitly says `yes`.

If the user requests changes:
1. Re-delegate to @planner with: `"$ARGUMENTS — revisions: <user feedback>"`
2. Wait until @planner confirms the updated `.claude/plan.md` has been written
3. Read the updated `.claude/plan.md` and present it to the user in full
4. Ask again — repeat this loop until the user explicitly says `yes`
```

- [ ] **Step 3: Verify the revision loop is present**

```bash
grep -n "Re-delegate to @planner" skills/ship/SKILL.md
```

Expected: prints the line number and content of the re-delegation instruction.

- [ ] **Step 4: Commit**

```bash
git add skills/ship/SKILL.md
git commit -m "feat: re-invoke @planner on plan revision instead of free-form edit"
```

---

## Task 2: Add explicit input routing to `@planner`

**Files:**
- Modify: `agents/planner.md`

The planner documents the GitHub issue number path but leaves the feature description path implicit and `gh issue list *` unexplained. Replace the single section with three explicit cases.

- [ ] **Step 1: Read the current input section**

```bash
grep -n "When given" agents/planner.md
```

Expected: one match — `## When given a GitHub issue number`

- [ ] **Step 2: Replace the input section**

Replace the entire `## When given a GitHub issue number` section (lines containing that heading through the blank line before `## Codebase analysis`) with:

```markdown
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
```

- [ ] **Step 3: Verify all three cases are present**

```bash
grep -n "Feature description\|Issue number\|Issue by keyword" agents/planner.md
```

Expected: three matches, one per case.

- [ ] **Step 4: Verify `gh issue list` is still in the tools frontmatter**

```bash
grep "gh issue list" agents/planner.md
```

Expected: two matches — one in the `tools:` line, one in the new instructions.

- [ ] **Step 5: Commit**

```bash
git add agents/planner.md
git commit -m "feat: document all three planner input types including gh issue list usage"
```

---

## Task 3: Add git commits, test runner, and update completion report in `@implementer`

**Files:**
- Modify: `agents/implementer.md`

Three changes to the same file — batched into one task since they are tightly related:
1. Add `Bash(make *)` to the tools frontmatter
2. Replace the `## After each step` section with commit + test instructions
3. Update the `## When finished` completion report to include test output

- [ ] **Step 1: Read the current implementer file**

```bash
cat agents/implementer.md
```

Expected: tools line ends with `Bash(cp *)`, After each step has two bullets, completion report has four bullets.

- [ ] **Step 2: Add `Bash(make *)` to the tools frontmatter**

Find the `tools:` line:
```
tools: Read, Write, Edit, Bash(git *), Bash(find *), Bash(cat *), Bash(mkdir *), Bash(mv *), Bash(cp *)
```

Replace with:
```
tools: Read, Write, Edit, Bash(git *), Bash(find *), Bash(cat *), Bash(mkdir *), Bash(mv *), Bash(cp *), Bash(make *)
```

- [ ] **Step 3: Replace the `## After each step` section**

Replace:
```markdown
## After each step

- Briefly note what was completed
- Flag any blockers or unexpected issues immediately
```

With:
```markdown
## After each step

1. Briefly note what was completed
2. Check whether a Makefile exists: `find . -maxdepth 1 -name Makefile`
   - If yes, run `make test` and note whether tests pass or fail
3. Stage and commit: `git add -A && git commit -m "step N: <description of what was done>"`
4. If tests fail or a blocker appears, stop immediately — do not continue to the next step
```

- [ ] **Step 4: Update the completion report `🧪` line**

Replace:
```markdown
- 🧪 Tests written and whether they pass
```

With:
```markdown
- 🧪 Tests written and whether they pass (include `make test` output summary if applicable)
```

- [ ] **Step 5: Verify all three changes are present**

```bash
grep -n "Bash(make \*)\|make test\|make test.*output" agents/implementer.md
```

Expected: three matches — one in tools, one in the after-each-step section, one in the completion report.

- [ ] **Step 6: Commit**

```bash
git add agents/implementer.md
git commit -m "feat: add make test runner and per-step git commits to implementer"
```

---

## Task 4: Create the `/shipplan` skill

**Files:**
- Create: `skills/shipplan/SKILL.md`

A thin planning-only skill. It delegates to `@planner`, presents the resulting `plan.md`, and stops — no implementation phase.

- [ ] **Step 1: Create the directory**

```bash
mkdir -p skills/shipplan
```

- [ ] **Step 2: Create `skills/shipplan/SKILL.md`**

```markdown
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
```

- [ ] **Step 3: Verify the file exists and has correct frontmatter**

```bash
grep -n "^name:\|^argument-hint:" skills/shipplan/SKILL.md
```

Expected:
```
2:name: shipplan
4:argument-hint: <feature description or "issue #N">
```

- [ ] **Step 4: Commit**

```bash
git add skills/shipplan/SKILL.md
git commit -m "feat: add /shipplan skill for plan-only workflow without implementation"
```

---

## Install reminder

After all tasks are complete, if this repo is installed via symlinks into `~/.claude/`, the new `skills/shipplan/` directory also needs a symlink:

```bash
ln -s ~/.claude/cc-ship/skills/shipplan ~/.claude/skills/shipplan
```

Update `README.md` install instructions to include this line.
