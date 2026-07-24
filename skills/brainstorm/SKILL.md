---
name: brainstorm
description: Interactive feature brainstorming session. Explores an idea through dialogue, produces a structured summary (splitting into multiple parts if the feature is too large), then captures it as a GitHub issue or as a phase in docs/plans/implementation-plan.md.
model: claude-opus-4-8
argument-hint: <feature idea (optional)>
---

Facilitate a brainstorming session for: "$ARGUMENTS"

## Step 1 — Open

If "$ARGUMENTS" is non-empty, acknowledge the idea in one sentence and ask the first clarifying question.

If "$ARGUMENTS" is empty, ask: "What's the idea you'd like to explore?"

## Step 2 — Dialogue

Ask questions one at a time to understand:
- The problem being solved and why it matters
- Who it's for (users, developers, systems)
- Constraints (technical, time, compatibility)
- What success looks like — specific, observable outcomes

**Use the `AskUserQuestion` tool for every clarifying question.** Supply 2–4 specific options that fit the context of the idea, with short descriptions. The tool always appends an "Other" option so the user can type a custom answer — you don't need to add one yourself.

Example option shapes (adapt to the actual idea):
- Who it's for → "End users", "Developers / CLI", "Internal tooling", "All of the above"
- Urgency → "Blocking current work", "Nice to have", "Future milestone"
- Scope → "Minimal MVP", "Full-featured", "Prototype to validate first"
- Technical constraint → "Must stay client-side", "Can add a backend", "Needs to work offline"

Ask only what you need. Stop when the picture is clear enough to write a structured summary.

## Step 3 — Scope check

After the dialogue, assess whether the feature is too large for a single unit of work (this becomes one GitHub issue or one implementation-plan phase, depending what's picked in Step 5 — the split is the same either way).

Split into 2–5 parts if the feature has clearly separable concerns — for example: distinct API and UI work, independent backend services, or acceptance criteria that belong to entirely different parts of the codebase.

If splitting, present the decomposition and let the user adjust before drafting summaries:

> "This looks too large for one piece of work. Here's how I'd break it down:
> 1. <Part 1 title> — <one-line reason>
> 2. <Part 2 title> — <one-line reason>
> Does this split make sense, or would you adjust it?"

Wait for the user to confirm or modify the split before proceeding.

If not splitting, say: "This fits in a single piece of work. Here's the summary:" then proceed directly to Step 4.

## Step 4 — Draft summary

Write the structured summary using the format below — this is the common working representation regardless of where it ends up in Step 5; the GitHub-issue and implementation-plan-phase formats are both derived from it. Present it to the user and ask:

> "Does this capture it correctly?"

Revise and re-present until the user confirms.

### Summary format — single piece of work

```
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
<comma-separated labels, e.g. enhancement, feature — omit section if none>
```

### Summary format — multiple pieces of work

Repeat the block below for each piece, separated by `---`. Number them and include implementation order in each block. Use `##` section headers (same as the single-piece format) so downstream tooling (`@issue-creator`, or the phase conversion in Step 5) can parse both formats identically.

```
## Issue 1 of N: <title>

## Problem
<what's broken or missing>

## Proposed solution
<what will be built>

## Acceptance criteria
- [ ] <condition>

## Implementation order
Issue 1 of N — start here.

## Out of scope
<what this does NOT cover>

## Labels
<comma-separated — omit section if none>

---

## Issue 2 of N: <title>

## Problem
...

## Proposed solution
...

## Acceptance criteria
- [ ] ...

## Implementation order
Issue 2 of N — implement after **<Issue 1 title>** is merged.

## Out of scope
...

## Labels
...
```

## Step 5 — Choose where this goes

Once the summary is confirmed, use `AskUserQuestion` to ask:

> "How should this be captured?"

Options: "GitHub issue", "Phase in implementation-plan.md", "Neither, just show me the summary"

- **GitHub issue** → delegate to @issue-creator, passing the entire Markdown summary block verbatim (unchanged from before)
- **Neither** → print the summary one final time so the user can copy it, then stop
- **Phase in implementation-plan.md** → see below

### Writing a phase into implementation-plan.md

1. **Find `docs/plans/implementation-plan.md` in the current repo.**
   - **Missing** (first phase-targeted brainstorm in this repo): create it with a short intro paragraph pointing to this repo's `CLAUDE.md` / `docs/architecture.md` for existing context (don't restate that context here — it drifts out of sync), then a `## Phased Implementation` heading, then a `## Implementation Order Summary` heading with an empty table (`| Phase | Name | Est. Complexity | Depends On |`). The new phase is **Phase 1** — there is no Phase 0; the app already exists, so there's no foundation phase to carve out.
   - **Exists:** read it, find the highest `### Phase N` heading, the new phase is **N+1**. If the file exists but has no `## Implementation Order Summary` heading (e.g. it predates this skill), add that heading and an empty table at the end of the file before inserting phases as described below.

2. **Convert each confirmed piece of work into a phase block.** If Step 3 split the work into multiple parts, they become sequential phases N, N+1, N+2, ... in the same order, each inserted in order right before `## Implementation Order Summary`:

   ```markdown
   ### Phase N — <title>

   **Goal:** <1-2 sentences — what exists when this phase is done, drawn from Problem + Proposed solution>

   **Tasks:**
   1. **<task>** — <detail: files touched, key decisions, drawn from Proposed solution + Acceptance criteria>
   2. **<task>** — ...

   **Not built (deliberately):** <from Out of scope — omit this line entirely if Out of scope was empty>
   ```

   Tasks describe *what* and *which files*, not full implementations — `/scope` does the deep verification-against-real-code pass and produces copy-pasteable code later. Don't front-load that detail here.

3. **Add one row per new phase** to the `## Implementation Order Summary` table: Phase number, Name, Est. Complexity (default "Medium" unless the dialogue clearly indicated otherwise), Depends On (default "—" unless a real dependency on an earlier phase surfaced during the dialogue).

4. **Show the rendered phase block(s)** before writing, then write the file. **Do not commit** — same as `/shipplan` never commits `.claude/plan.md`. Tell the user:

   > "Phase N added to `docs/plans/implementation-plan.md`. Review it, then commit when ready. Run `/scope phase N` to break it into task docs for Hermes."
