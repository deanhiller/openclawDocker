#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

# Check which container (if any) is actually running on the gateway port
RUNNING_CONTAINER=$(docker ps --format '{{.Names}}' --filter "publish=18789" 2>/dev/null || true)

if [ -z "$RUNNING_CONTAINER" ]; then
    echo "No OpenClaw Docker is running right now."
    exit 0
fi

# Extract project name from container name (e.g. "openclawdocker1-gateway" -> "openclawdocker1")
RUNNING_PROJECT="${RUNNING_CONTAINER%-gateway}"

if [ "$RUNNING_PROJECT" != "$COMPOSE_PROJECT_NAME" ]; then
    # Figure out the sibling directory name for a helpful message
    if [[ "$RUNNING_PROJECT" == *"1"* ]]; then
        SIBLING="openclawDocker1"
    else
        SIBLING="openclawDocker2"
    fi
    echo "This Docker is not running. The running gateway is ${RUNNING_PROJECT}."
    echo "Change to ../$(basename "$SIBLING") and stop that one."
    exit 1
fi

cd "$REPO_DIR"

echo "Stopping OpenClaw gateway (${COMPOSE_PROJECT_NAME})..."
docker compose down
echo "Done."
