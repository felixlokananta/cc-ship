<div align="center">

<img src="assets/logo.svg" alt="cc-ship" width="600"/>

<br/>

A Claude Code skill that orchestrates a brainstorm → plan → implement workflow.<br>
The main agent plans (with live clarifying questions). You review. Haiku executes.

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
<td>Plan + review + implement. The main agent plans the work (with live clarifying questions) and writes <code>.claude/plan.md</code>. You approve. Haiku executes step by step and opens a PR.</td>
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
         planning phase (main agent) ◄───────────────────────────┘
         • detects input type (description / issue # / keyword)
         • fetches GitHub issue via gh CLI if needed
         • reads the codebase
         • asks clarifying questions (live via AskUserQuestion)
         • writes .claude/plan.md
                      │
                      ▼
               YOU review the plan
               (request changes → main agent re-plans)
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

Only implementation is isolated: the implementer runs in its own context window and reads .claude/plan.md fresh. Planning runs in the main agent and can include live clarifying questions.

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

# Plan + implement from a keyword (searches open issues)
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
├── docs/
│   └── planning-process.md  # canonical planning process (followed by main agent)
├── agents/
│   ├── implementer.md       # Haiku — executes .claude/plan.md, commits per step
│   └── issue-creator.md     # Haiku — detects repo, files GitHub issues
├── skills/
│   ├── brainstorm/
│   │   └── SKILL.md         # /brainstorm — dialogue → summary → issues
│   ├── ship/
│   │   └── SKILL.md         # /ship — plan + review + implement + PR
│   └── shipplan/
│       └── SKILL.md         # /shipplan — plan + review only
└── pi/                      # port of /ship to the Pi coding agent (see below)
```

---

## Pi port

`pi/` ports the `/ship` plan-then-implement workflow to the [Pi coding agent](https://github.com/earendil-works/pi). It contains the `/ship` prompt template (`pi/prompts/ship.md`), the implementer agent definition (`pi/agents/implementer.md`), and vendored `question`/`subagent` extensions from Pi's examples (`pi/extensions/`). The plan is written to `.pi/plan.md` instead of `.claude/plan.md`.

```bash
bash ~/.claude/cc-ship/pi/install.sh   # symlinks the pi files into ~/.pi/agent
```
