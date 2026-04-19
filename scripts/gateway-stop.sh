#!/usr/bin/env bash
# Stop JUST the openclaw gateway process inside the running container, without
# touching the container itself — so any shells and Claude Code sessions in it
# keep running. Frees the gateway's memory/CPU.
#
# Works by creating a sentinel file /tmp/openclaw-gateway-disabled that the
# entrypoint loop checks before each (re)start, then killing the current
# openclaw process. Counterpart: scripts/gateway-start.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"
CONTAINER="${COMPOSE_PROJECT_NAME}-gateway"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Nothing to stop."
  exit 0
fi

echo "Disabling gateway and killing the running process inside $CONTAINER..."
docker exec "$CONTAINER" bash -c '
  touch /tmp/openclaw-gateway-disabled
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
echo "Done. Container still up. Relaunch gateway: scripts/gateway-start.sh"
