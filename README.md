<div align="center">

# cc-ship

**Think with Opus. Build with Haiku. Ship with `/ship`.**

A Claude Code skill that orchestrates a brainstorm → plan → implement workflow using subagents.<br>
Opus explores ideas and writes plans. You review. Haiku executes.

</div>

---

## Skills

<table>
<tr>
<td><code>/brainstorm</code></td>
<td>Explore a feature idea through dialogue, produce a structured summary, and optionally file GitHub issues — before a single line of code is planned.</td>
</tr>
<tr>
<td><code>/ship</code></td>
<td>Plan + review + implement. Opus analyses the codebase and writes <code>.claude/plan.md</code>. You approve. Haiku executes step by step and opens a PR.</td>
</tr>
<tr>
<td><code>/shipplan</code></td>
<td>Plan only — get the full implementation plan without triggering implementation. Run <code>/ship</code> when ready.</td>
</tr>
</table>

---

## How it works

```
/brainstorm <idea>
      │
      ▼
  dialogue (Opus)
  scope check → split into issues if needed
  structured summary → you confirm
      │
      ▼
  @issue-creator (Haiku)
  detects repo → gh issue create (one per issue, in order)
      │
      └──── /ship #N  ──────────────────────────────────────────┐
                                                                 │
/ship <description or "issue #N">    /shipplan <same>           │
       │                                      │                  │
       └──────────────┬───────────────────────┘                  │
                      ▼                                          │
               @planner (Opus) ◄────────────────────────────────┘
               • detects input type (description / issue # / keyword)
               • fetches GitHub issue via gh CLI if needed
               • reads the codebase
               • writes .claude/plan.md
                      │
                      ▼
               YOU review the plan
               (request changes → @planner revises)
                      │
          ┌───────────┴────────────┐
      /ship only               /shipplan stops here
          │
          ▼
    @implementer (Haiku)
    • confirms understanding before touching files
    • executes .claude/plan.md step by step
    • runs make test + commits after each step
    • opens a PR when done
```

Each agent runs in its own context window — planning context never bleeds into implementation.

---

## Requirements

- [Claude Code](https://claude.ai/code) v2.1+
- [GitHub CLI](https://cli.github.com/) (`gh`) — required for issue references in `/ship`/`/shipplan`, and for filing issues at the end of `/brainstorm`
- `gh auth login` completed in your terminal

---

## Install

```bash
git clone https://github.com/YOUR_HANDLE/cc-ship.git ~/.claude/cc-ship
bash ~/.claude/cc-ship/install.sh
```

Symlinks mean `git pull` propagates changes instantly — no re-running the install script.

## Update

```bash
cd ~/.claude/cc-ship && git pull
```

---

## Usage

```bash
# Brainstorm a feature idea → file GitHub issues
/brainstorm add email notifications to event assignments

# Plan + implement from a feature description
/ship add email notifications to event assignments

# Plan + implement from a GitHub issue
/ship issue #12

# Plan + implement from a keyword (planner searches open issues)
/ship the auth bug

# Plan only — review before deciding to implement
/shipplan add email notifications to event assignments
/shipplan issue #12
```

---

## Structure

```
cc-ship/
├── install.sh
├── agents/
│   ├── planner.md        # Opus  — reads codebase, writes .claude/plan.md
│   ├── implementer.md    # Haiku — executes .claude/plan.md, commits per step
│   └── issue-creator.md  # Haiku — detects repo, files GitHub issues
└── skills/
    ├── brainstorm/
    │   └── SKILL.md      # /brainstorm — dialogue → summary → issues
    ├── ship/
    │   └── SKILL.md      # /ship — plan + review + implement + PR
    └── shipplan/
        └── SKILL.md      # /shipplan — plan + review only
```
