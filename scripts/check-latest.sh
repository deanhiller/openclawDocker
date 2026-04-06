#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

CURRENT_VERSION=$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "unknown")
LATEST_VERSION=$(npm view openclaw version 2>/dev/null || echo "unknown")

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "unknown" ]; then
    echo ""
    echo "Update available! Run:"
    echo "  ./scripts/upgrade.sh $LATEST_VERSION"
fi