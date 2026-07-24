#!/usr/bin/env bash
set -euo pipefail

PI_SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p ~/.pi/agent/prompts ~/.pi/agent/agents ~/.pi/agent/extensions

# Remove the superseded ship.ts extension — its /ship command collides with the prompt template
if [ -e ~/.pi/agent/extensions/ship.ts ] && [ ! -L ~/.pi/agent/extensions/ship.ts ]; then
  rm -f ~/.pi/agent/extensions/ship.ts
  echo "removed superseded ~/.pi/agent/extensions/ship.ts"
fi

ln -sf  "$PI_SRC_DIR/prompts/ship.md"        ~/.pi/agent/prompts/ship.md
ln -sf  "$PI_SRC_DIR/agents/implementer.md"  ~/.pi/agent/agents/implementer.md
ln -sf  "$PI_SRC_DIR/extensions/question.ts" ~/.pi/agent/extensions/question.ts
ln -sfn "$PI_SRC_DIR/extensions/subagent"    ~/.pi/agent/extensions/subagent

echo "cc-ship pi files installed from $PI_SRC_DIR"
