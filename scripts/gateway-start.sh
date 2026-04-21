#!/usr/bin/env bash
# Launch the openclaw gateway process inside an already-running container.
# Output is routed to PID 1's stdout/stderr via /proc/1/fd/{1,2} so it reaches
# `docker logs` (and scripts/logs.sh). Idempotent: no-op if already running.
# Counterpart: scripts/gateway-stop.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"
CONTAINER="${COMPOSE_PROJECT_NAME}-gateway"

if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "Container $CONTAINER is not running. Run scripts/start.sh first."
  exit 1
fi

# A duplicate gateway would fail to bind 127.0.0.1:18789 and produce confusing
# output, so pre-check.
if docker exec "$CONTAINER" pgrep -f '^openclaw gateway$' >/dev/null 2>&1; then
  echo "openclaw gateway is already running in $CONTAINER. No action taken."
  exit 0
fi

echo "Launching openclaw gateway in $CONTAINER (output -> docker logs)..."
docker exec -d "$CONTAINER" bash -c 'openclaw gateway > /proc/1/fd/1 2> /proc/1/fd/2'
echo "Done. Tail output: scripts/logs.sh"
