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

# The container always starts (so you can shell in and use claude).
# The opt-out only skips the heavy `openclaw gateway` process inside the
# container — that's the several-GB memory hog. Claude Code and shells are
# unaffected. See entrypoint.sh for how OPENCLAW_START_GATEWAY is honored.
# Skip the prompt if stdin isn't a TTY (e.g. piped/CI) or OPENCLAW_ASSUME_YES=1.
if [ -t 0 ] && [ "${OPENCLAW_ASSUME_YES:-0}" != "1" ]; then
  read -r -p "Launch the openclaw gateway process inside the container? [Y/n] " reply
  case "${reply:-Y}" in
    [Nn]*)
      export OPENCLAW_START_GATEWAY=0
      echo "Gateway process disabled. Container will still start so you can shell in and run claude."
      ;;
    *)
      export OPENCLAW_START_GATEWAY=1
      ;;
  esac
else
  export OPENCLAW_START_GATEWAY="${OPENCLAW_START_GATEWAY:-1}"
fi

# Ensure all host-side mount sources exist before Docker tries to mount them.
# Docker auto-creates missing mount sources as root-owned, which breaks things.
# ~/.claudeDocker mirrors the container's $HOME — see ~/.claudeDocker/README.md.
mkdir -p "$HOME/.claudeDocker/.claude" \
         "$HOME/.claudeDocker/.local/bin" \
         "$HOME/.claudeDocker/.local/share/claude" \
         "$HOME/.claudeDocker/.claude-mem"
[ -e "$HOME/.claudeDocker/.claude.json" ] || echo '{}' > "$HOME/.claudeDocker/.claude.json"

cd "$REPO_DIR"
docker compose up -d

echo ""
echo "OpenClaw gateway is running."
echo "  Web UI:   http://localhost:18789"
echo "  Logs:     scripts/logs.sh"
echo "  Shell:    scripts/shell.sh"
echo "  Stop:     scripts/stop.sh"
