#!/usr/bin/env bash
# Relaunch the openclaw gateway process inside an already-running container.
# Removes the sentinel file the entrypoint loop checks; the loop will pick it
# up within a few seconds and start `openclaw gateway`. Counterpart:
# scripts/gateway-stop.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"
CONTAINER="${COMPOSE_PROJECT_NAME}-gateway"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Run scripts/start.sh first."
  exit 1
fi

echo "Enabling gateway in $CONTAINER (entrypoint loop will start it within ~5s)..."
docker exec "$CONTAINER" bash -c 'rm -f /tmp/openclaw-gateway-disabled'
echo "Done. Tail logs: scripts/logs.sh"
