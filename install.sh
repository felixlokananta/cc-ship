#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/agents ~/.claude/skills

# Remove stale planner symlink from prior installs (planning now runs in main agent, documented at docs/planning-process.md)
[ -L ~/.claude/agents/planner.md ] && rm -f ~/.claude/agents/planner.md

ln -sf "$REPO_DIR/agents/implementer.md"   ~/.claude/agents/implementer.md
ln -sf "$REPO_DIR/agents/issue-creator.md" ~/.claude/agents/issue-creator.md
ln -sf "$REPO_DIR/skills/ship"             ~/.claude/skills/ship
ln -sf "$REPO_DIR/skills/shipplan"         ~/.claude/skills/shipplan
ln -sf "$REPO_DIR/skills/brainstorm"       ~/.claude/skills/brainstorm

echo "cc-ship installed from $REPO_DIR"
