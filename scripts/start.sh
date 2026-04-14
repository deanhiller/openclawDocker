#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Derive project name from the directory so multiple clones use separate images/containers.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

echo "=== OpenClaw Gateway Start (${COMPOSE_PROJECT_NAME}) ==="
echo ""

# Always mount the full workspace root — per-project agent scoping is handled
# inside the container by bin/openclawTui.sh, so no prompt needed here.
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/openclaw}"
export OPENCLAW_WORKSPACE

echo "Workspace: $OPENCLAW_WORKSPACE"
echo ""

# Ensure isolated Claude Code state exists on host before mounting — otherwise
# Docker would auto-create ~/.claudeDocker.json as a directory.
mkdir -p "$HOME/.claudeDocker"
[ -e "$HOME/.claudeDocker.json" ] || echo '{}' > "$HOME/.claudeDocker.json"

# Ensure mounted persistent-state dirs exist on host before Docker tries to mount them.
# (Docker auto-creates missing mount sources as root-owned, which breaks things.)
mkdir -p "$HOME/.claudeDocker/.local/bin" \
         "$HOME/.claudeDocker/.local/share/claude" \
         "$HOME/.claudeDocker/.claude-mem"

cd "$REPO_DIR"
docker compose up -d

echo ""
echo "OpenClaw gateway is running."
echo "  Web UI:   http://localhost:18789"
echo "  Logs:     scripts/logs.sh"
echo "  Shell:    scripts/shell.sh"
echo "  Stop:     scripts/stop.sh"
