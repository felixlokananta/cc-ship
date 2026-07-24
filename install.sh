#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.claude/agents ~/.claude/skills

# Remove stale planner symlink from prior installs (planning now runs in main agent, documented at docs/planning-process.md)
[ -L ~/.claude/agents/planner.md ] && rm -f ~/.claude/agents/planner.md

# Remove self-referential symlinks prior installs left inside the repo (ln -sf without -n dereferenced the existing skill links)
for skill in ship shipplan brainstorm scope; do
  [ -L "$REPO_DIR/skills/$skill/$skill" ] && rm -f "$REPO_DIR/skills/$skill/$skill"
done

# -n: replace an existing symlink-to-directory instead of creating the link inside it
ln -sfn "$REPO_DIR/agents/implementer.md"   ~/.claude/agents/implementer.md
ln -sfn "$REPO_DIR/agents/issue-creator.md" ~/.claude/agents/issue-creator.md
ln -sfn "$REPO_DIR/skills/ship"             ~/.claude/skills/ship
ln -sfn "$REPO_DIR/skills/shipplan"         ~/.claude/skills/shipplan
ln -sfn "$REPO_DIR/skills/brainstorm"       ~/.claude/skills/brainstorm
ln -sfn "$REPO_DIR/skills/scope"            ~/.claude/skills/scope

echo "cc-ship installed from $REPO_DIR"
