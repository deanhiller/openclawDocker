#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Derive project name from the directory so multiple clones build separate images.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

VERSION=$(cat "$REPO_DIR/VERSION")
echo "Building openclaw-${COMPOSE_PROJECT_NAME} image (version $VERSION)..."

cd "$REPO_DIR"
docker compose build

echo "Done. Image openclaw-${COMPOSE_PROJECT_NAME}:latest built with openclaw@$VERSION"
