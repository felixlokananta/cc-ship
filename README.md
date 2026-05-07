# cc-ship

> Think with Opus. Build with Haiku. Ship with `/ship`.

A Claude Code skill that orchestrates a plan-then-implement workflow using subagents. Opus analyses your codebase and writes a detailed plan. You review it. Haiku executes it.

## How it works

```
/ship <feature description or "issue #N">
       │
       ▼
  @planner (Opus)
  • fetches GitHub issue via gh CLI (if given issue number)
  • reads the codebase
  • writes .claude/plan.md
       │
       ▼
  YOU review the plan
       │
       ▼
  @implementer (Haiku)
  • executes .claude/plan.md step by step
  • writes tests
  • reports back
```

Each agent runs in its own context window — planning context never bleeds into implementation.

## Requirements

- [Claude Code](https://claude.ai/code) v2.1+
- [GitHub CLI](https://cli.github.com/) (`gh`) — only needed if using issue references
- `gh auth login` completed in your terminal

## Install

```bash
git clone https://github.com/YOUR_HANDLE/cc-ship.git ~/.claude/cc-ship

# Create directories if they don't exist
mkdir -p ~/.claude/agents ~/.claude/skills

# Symlink agents and skills
ln -s ~/.claude/cc-ship/agents/planner.md ~/.claude/agents/planner.md
ln -s ~/.claude/cc-ship/agents/implementer.md ~/.claude/agents/implementer.md
ln -s ~/.claude/cc-ship/skills/ship ~/.claude/skills/ship
```

Symlinks mean a `git pull` updates everything instantly.

## Usage

```bash
# From a feature description
/ship add email notifications to event assignments

# From a GitHub issue
/ship issue #12

# Natural language with context
/ship lets work on github issue #12, please check out the issue so you can understand
```

## What gets created

- `.claude/plan.md` — the implementation plan written by Opus, saved in your project

You can commit this file if you want a record of what was planned and why.

## Updating

```bash
cd ~/.claude/cc-ship && git pull
```

## Structure

```
cc-ship/
├── README.md
├── agents/
│   ├── planner.md       # Opus — reads codebase, writes .claude/plan.md
│   └── implementer.md   # Haiku — executes .claude/plan.md
└── skills/
    └── ship/
        └── SKILL.md     # /ship orchestrator
```
