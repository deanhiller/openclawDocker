#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

cd "$REPO_DIR"

# Always mount the full workspace root — per-project agent scoping is handled
# inside the container by bin/openclawTui.sh, so no prompt needed here.
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/openclaw}"
export OPENCLAW_WORKSPACE

# Ensure isolated Claude Code state exists on host before mounting.
mkdir -p "$HOME/.claudeDocker"
[ -e "$HOME/.claudeDocker.json" ] || echo '{}' > "$HOME/.claudeDocker.json"

echo "Restarting OpenClaw gateway..."
# `up -d --force-recreate` picks up new volume mounts and compose changes;
# plain `docker compose restart` would not.
docker compose up -d --force-recreate openclaw-gateway
echo "Done. Web UI: http://localhost:18789"
