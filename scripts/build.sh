#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Derive project name from the directory so multiple clones build separate images.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

VERSION=$(cat "$REPO_DIR/VERSION")

# Compute git hash; append -dev if there are uncommitted changes
GIT_HASH=$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
if ! git -C "$REPO_DIR" diff --quiet HEAD 2>/dev/null || \
   ! git -C "$REPO_DIR" diff --cached --quiet HEAD 2>/dev/null || \
   [ -n "$(git -C "$REPO_DIR" ls-files --others --exclude-standard 2>/dev/null)" ]; then
  GIT_HASH="${GIT_HASH}-dev"
fi

echo "Building openclaw-${COMPOSE_PROJECT_NAME} image (version $VERSION, git $GIT_HASH)..."

cd "$REPO_DIR"
docker compose build --build-arg GIT_HASH="$GIT_HASH"

echo "Done. Image openclaw-${COMPOSE_PROJECT_NAME}:latest built with openclaw@$VERSION"
