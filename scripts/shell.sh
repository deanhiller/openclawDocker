#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

cd "$REPO_DIR"

echo "Entering shell inside ${COMPOSE_PROJECT_NAME}-gateway container..."
echo "(Type 'exit' to leave)"
echo ""
docker compose exec openclaw-gateway /bin/bash
