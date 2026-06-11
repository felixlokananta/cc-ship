#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/agents ~/.claude/skills

ln -sf "$REPO_DIR/agents/planner.md"       ~/.claude/agents/planner.md
ln -sf "$REPO_DIR/agents/implementer.md"   ~/.claude/agents/implementer.md
ln -sf "$REPO_DIR/agents/issue-creator.md" ~/.claude/agents/issue-creator.md
ln -sf "$REPO_DIR/skills/ship"             ~/.claude/skills/ship
ln -sf "$REPO_DIR/skills/shipplan"         ~/.claude/skills/shipplan
ln -sf "$REPO_DIR/skills/brainstorm"       ~/.claude/skills/brainstorm

echo "cc-ship installed from $REPO_DIR"
