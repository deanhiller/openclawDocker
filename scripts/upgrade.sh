#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenClaw Upgrade ==="
echo ""

# Check if version argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 2026.4.5"
    echo ""
    echo "To check latest version: npm view openclaw version"
    exit 1
fi

NEW_VERSION="$1"
CURRENT_VERSION=$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "")

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
    echo "Already on version $NEW_VERSION"
    exit 0
fi

echo "Upgrading from ${CURRENT_VERSION:-unknown} to $NEW_VERSION"
echo ""

# Step 1: Tag current image so we can revert
echo "1. Tagging current image for rollback..."
if docker image inspect openclaw-local:latest >/dev/null 2>&1; then
    docker tag openclaw-local:latest "openclaw-local:previous"
    echo "   Tagged openclaw-local:latest as openclaw-local:previous"
else
    echo "   No existing image to tag (first build)"
fi

# Step 2: Stop the gateway
echo "2. Stopping OpenClaw gateway..."
"$SCRIPT_DIR/stop.sh"

# Step 3: Save old version and update VERSION file
echo "3. Updating VERSION file..."
if [ -n "$CURRENT_VERSION" ]; then
    echo "$CURRENT_VERSION" > "$REPO_DIR/VERSION.previous"
    echo "   Saved previous version ($CURRENT_VERSION) to VERSION.previous"
fi
echo "$NEW_VERSION" > "$REPO_DIR/VERSION"

# Step 4: Upgrade local CLI (TUI)
echo "4. Upgrading local OpenClaw CLI to $NEW_VERSION..."
npm install -g "openclaw@$NEW_VERSION"

# Step 4b: Remove local gateway service (gateway runs in Docker only)
echo "4b. Removing local gateway service (Docker handles this)..."
openclaw daemon uninstall 2>/dev/null || true
rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Step 5: Rebuild image
echo "5. Rebuilding gateway image..."
"$SCRIPT_DIR/build.sh"

echo ""
echo "=== Upgrade complete ==="
echo "OpenClaw upgraded from ${CURRENT_VERSION:-unknown} to $NEW_VERSION"
echo ""
echo "Run scripts/start.sh to start the gateway."
echo ""
echo "If something breaks, revert with:"
echo "  scripts/revert.sh"
