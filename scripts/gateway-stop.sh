#!/usr/bin/env bash
# Kill the openclaw gateway process inside the running container without
# touching the container itself — shells and Claude Code sessions keep running.
# Gateway stays dead until explicitly restarted via scripts/gateway-start.sh;
# the entrypoint does not auto-relaunch. Counterpart: scripts/gateway-start.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"
CONTAINER="${COMPOSE_PROJECT_NAME}-gateway"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Nothing to stop."
  exit 0
fi

echo "Killing openclaw gateway process inside $CONTAINER..."
docker exec "$CONTAINER" bash -c '
  PIDS=$(pgrep -f "^openclaw gateway$" || true)
  if [ -n "$PIDS" ]; then
    echo "Killing openclaw gateway PID(s): $PIDS"
    kill -TERM $PIDS || true
    sleep 2
    kill -KILL $PIDS 2>/dev/null || true
  else
    echo "No openclaw gateway process was running."
  fi
'
echo "Done. Container still up. Relaunch: scripts/gateway-start.sh"
