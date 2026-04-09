#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

VERSION=$(cat "$REPO_DIR/VERSION")
echo "Building openclaw-local image (version $VERSION)..."

cd "$REPO_DIR"
docker compose build --no-cache

echo "Done. Image openclaw-local:latest built with openclaw@$VERSION"
