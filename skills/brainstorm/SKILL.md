---
name: brainstorm
description: Interactive feature brainstorming session. Explores an idea through dialogue, produces a structured summary (splitting into multiple issues if the feature is too large), then optionally delegates to @issue-creator to file GitHub issues.
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

After the dialogue, assess whether the feature is too large for a single GitHub issue.

Split into 2–5 sub-issues if the feature has clearly separable concerns — for example: distinct API and UI work, independent backend services, or acceptance criteria that belong to entirely different parts of the codebase.

If splitting, present the decomposition and let the user adjust before drafting summaries:

> "This looks too large for one issue. Here's how I'd break it down:
> 1. <Issue 1 title> — <one-line reason>
> 2. <Issue 2 title> — <one-line reason>
> Does this split make sense, or would you adjust it?"

Wait for the user to confirm or modify the split before proceeding.

If not splitting, say: "This fits in a single issue. Here's the summary:" then proceed directly to Step 4.

## Step 4 — Draft summary

Write the structured summary using the format below. Present it to the user and ask:

> "Does this capture it correctly?"

Revise and re-present until the user confirms.

### Summary format — single issue

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

### Summary format — multiple issues

Repeat the block below for each issue, separated by `---`. Number them and include implementation order in each block. Use `##` section headers (same as the single-issue format) so `@issue-creator` can parse both formats identically.

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

## Step 5 — Issue prompt

Once the summary is confirmed, use `AskUserQuestion` to ask:

> "Create a GitHub issue from this?"

Options: "Yes, create the issue(s)", "No, just show me the summary"

- **Yes** → delegate to @issue-creator, passing the entire Markdown summary block verbatim
- **No** → print the summary one final time so the user can copy it, then stop
