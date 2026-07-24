---
name: scope
description: Use when breaking a phase from docs/plans/implementation-plan.md into task documents for the local model (Hermes) to execute, e.g. "/scope phase 2" or "scope the next phase into tasks for Hermes".
---

# Scope a Phase into Local-Model Tasks

## Overview

Turn one phase of `docs/plans/implementation-plan.md` into a folder of numbered task docs under `docs/plans/tasks/phaseN/`, each small and complete enough for **Hermes**, a smaller local model, to execute without designing anything.

**Core principle:** Hermes transcribes and wires. It does not design, guess API shapes, or make architectural calls. Every decision is made here, at scope time.

This works the same in every ChurchUp repo (`churchup-api`, `churchup-ui`, `churchup-landing`, `churchup-mobile`) — same plan/task-folder convention, same Hermes executor, same discipline. What differs per repo is *which engineer skill Hermes loads* and *where the real contract lives* — both covered in the Process below.

## The Plan Is a Forecast, Not Ground Truth

`implementation-plan.md` was written before any code existed and **without reading the whole system**. It is wrong in two directions, and you must check both.

### It is wrong about what's already built

Earlier phases overshoot. In one mobile phase, the plan listed "Auth service" and "Types" as Phase 1 tasks; Phase 0 had already built `AuthService` (all six methods), `types/auth.ts`, and the auth guard. It listed "Bottom tab navigation" as a Phase 2 task; Phase 0 had already shipped the tabs and icons.

**Never write a task for an artifact you have not confirmed is missing.**

### It is wrong about what a contract actually returns

This is the one that ships bugs. The plan's endpoint/contract list is an *assumption*, not a contract. Verified counter-examples from the mobile plan, both of which would have broken Phase 2:

- The plan said the dashboard shows today's events via `GET /ministry/event/`. That endpoint is `IsChurchAdminOrEventMinistryLeader` — it **403s for a regular member**, the app's most common user.
- The plan said `GET /core/dashboard/summary/` returns "total members, upcoming events count". It is actually **role-shaped**, returning one of three different payloads (admin / ministry_leader / member).

**Never write a task against a contract whose real shape and permissions you have not read.**

## Process

### 1. Read the phase section in `docs/plans/implementation-plan.md`

Get the intended goal, task list, and deliverable.

### 2. Read the previous phase's task folder

`docs/plans/tasks/phase<N-1>/` — the README and 2–3 task files. Match its structure, tone, and level of detail exactly. Consistency matters more than your preferences.

### 3a. Verify against this repo's own codebase

For **every** artifact the phase lists — each service, type, hook, component, screen, model, view — check whether it already exists. Use whatever discovery commands fit this repo (`find`/`grep`/`ls`); read the actual committed files, not the previous phase's task docs (docs describe intent; files are truth).

Sort every listed artifact into:
- **Already exists** → cut from scope; list it in the README's "already done" callout so Hermes does not touch it
- **Exists but incomplete** → task is a targeted edit, and you quote the current file so Hermes edits rather than rewrites
- **Missing** → real work; becomes a task

### 3b. Verify external contracts against the repo that owns them

Skip this step entirely if **this repo is the source of truth** for the phase's contracts — e.g. you're scoping backend work in `churchup-api` itself. In that case 3a's filesystem check already covers it.

Otherwise (you're in `churchup-ui`, `churchup-landing`, or `churchup-mobile` and the phase touches an API): find the monorepo root `CLAUDE.md` — check `../CLAUDE.md` first (true when this repo lives inside the `churchup/` folder); if not there, check `../churchup/CLAUDE.md` (true when this repo is a sibling of the `churchup/` folder, e.g. `churchup-mobile`). Read its Cross-Project Architecture section to confirm which sibling repo owns the contract (almost always `churchup-api`) and its path, then read the real thing:

```bash
cd <path to the owning repo from root CLAUDE.md>
# What does it return, and what shape?
grep -rn -A20 "class <Name>View" <app>/views.py
cat <app>/serializers/*.py
# WHO IS ALLOWED TO CALL IT? — the step most often skipped
grep -n "permission_classes" <app>/views.py
```

Check **permissions**, not just payloads. Consumer repos rarely have a leadership-role user as their primary caller; an endpoint that works for you in testing as an admin can be dead for most of the user base.

When the owning repo contradicts the plan, **the owning repo wins.** Design the task around reality and note the discrepancy in the README so the plan gets fixed.

### 4. Split the remaining work

Sizing rules for the local model:

- **Shared primitives first.** If 3 screens/views need an input and a button, task 1 builds them. Otherwise Hermes reinvents them 3 inconsistent ways.
- **One screen / one feature per task.** Roughly one new source file plus its test file.
- **Order strictly by dependency.** Each task lists what it depends on.
- **5–7 tasks per phase.** More than that means the phase is too big; fewer means tasks are too fat.

Number tasks phase-prefixed so they stay unique on the Kanban board: Phase 1 → `task-101`…, Phase 2 → `task-201`…

### 5. Write the task docs

One file per task: `docs/plans/tasks/phaseN/task-N0M-short-slug.md`, with these sections in order:

| Section | Content |
|---|---|
| `# Task N0M: Title` | — |
| `## Goal` | 1–3 sentences. What exists at the end. |
| `## Prerequisites` | Which tasks/phases must be done, plus `Load skill: skill_view(name='<engineer skill>')` — see table below for which skill |
| `## Tasks` | Numbered steps, each with the **complete, copy-pasteable code** for the file |
| `## Acceptance Criteria` | Numbered, checkable. Always includes this repo's typecheck/lint/test commands — check its `CLAUDE.md` Quick Reference section rather than assuming a toolchain. |
| `## Notes` | Gotchas, conventions, and anything to verify against the owning repo |

Which engineer skill Hermes loads depends on which repo you're scoping:

| Repo | Engineer skill |
|---|---|
| `churchup-api` | `churchup-backend-engineer` |
| `churchup-ui` | `churchup-frontend-engineer` |
| `churchup-landing` | `churchup-frontend-engineer` |
| `churchup-mobile` | `churchup-mobile-engineer` |

### 6. Write the folder `README.md`

Contains: the "already done in earlier phases — do not rebuild" callout, the task table (Task / Name / Depends On / Est. Effort), the "one task per work session" rule, and phase completion criteria.

## Give Code, Not Specifications

This is what makes a task digestible for a small model. The principle holds regardless of language — Python, TypeScript, whatever the repo uses.

<Bad>
```markdown
### 2. Create the login screen
Build a screen with email and password inputs, validation, a loading
state, error display, and navigation to the dashboard on success.
```
</Bad>

<Good>
````markdown
### 2. Replace `app/(auth)/login.tsx`

```tsx
export default function LoginScreen() {
  const router = useRouter();
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  // ...every line Hermes needs, complete and runnable
}
```
````
</Good>

Write the test code out in full too. Hermes should be able to create the files, run the repo's typecheck/test commands, and be done.

## Never Guess a Contract — Go Read It

When you are unsure of a contract's shape, field name, response envelope, or who is allowed to call it: **do not invent a plausible one, and do not punt it to a "verify later" note.** Go find the repo that owns it (step 3b) and read the view, the serializer, and the permission classes. Transcribe the real names into the task.

A guess becomes a bug Hermes ships with total confidence — it has no way to know you were unsure.

Only when the owning repo genuinely cannot answer (endpoint doesn't exist yet, behavior depends on runtime data) do you fall back to an explicit Note:

> **Verify before shipping.** `confirmPasswordReset(token, password)` POSTs `{ token, password }`. Confirm whether the endpoint also requires a `uid`; if so, read it from `useLocalSearchParams` and update the service.

## Red Flags — Stop and Recheck

| Thought | Reality |
|---|---|
| "The plan lists this contract, so I know its shape" | The plan never read the owning repo. Go find it (step 3b). |
| "The endpoint constant exists in this repo's client, so it's fine" | A URL string tells you nothing about the payload or who may call it. |
| "I've got the response shape; that's the contract" | You're half done. Read `permission_classes` too — it may 403 for regular members. |
| "I'm not sure of the field names, I'll pick something sensible" | Never guess. Hermes will ship your guess with total confidence. |
| "The plan lists it, so it's a task" | Check the filesystem first. Earlier phases overshoot. |
| "I'll describe the component and let Hermes write it" | Small models design badly. Give complete code. |
| "These two tasks are small, I'll merge them" | Merging inflates per-task context. Keep them separate. |
| "I'll skim the previous phase's task docs for current state" | Docs are intent. Read the committed files. |
| "The phase is big, I'll write 12 tasks" | The phase is too big — re-read it; much is likely already built. |
| "I'm in churchup-api, I still need to check a sibling repo" | If this repo is the source of truth for the contract, 3a already covers it — skip 3b. |

## Common Mistakes

- **Trusting the plan's contract list as ground truth** — the single most expensive mistake. It produces tasks that compile, pass their mocked tests, and 403 in production. Read the real view/serializer.
- **Checking the payload but not the permissions** — half a contract. An admin/leader-only permission class means regular users get nothing.
- **Scoping from the plan alone** — produces tasks that rebuild existing code. Always diff plan against filesystem.
- **Vague acceptance criteria** ("login works") — Hermes cannot self-check. Use commands and observable behavior.
- **Forgetting the "already done" callout** — Hermes will happily overwrite an earlier phase's tested code.
- **Inconsistent numbering across phases** — breaks Kanban uniqueness. Phase-prefix every task ID.
- **Loading the wrong engineer skill** — use the repo → skill table in step 5, not whatever skill was loaded last session.
