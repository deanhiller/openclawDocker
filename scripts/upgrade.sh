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

# Step 1: Stop the gateway
echo "1. Stopping OpenClaw gateway..."
"$SCRIPT_DIR/stop.sh"

# Step 2: Update version file
echo "2. Updating VERSION file..."
echo "$NEW_VERSION" > "$REPO_DIR/VERSION"

# Step 3: Upgrade local CLI (TUI)
echo "3. Upgrading local OpenClaw CLI to $NEW_VERSION..."
npm install -g "openclaw@$NEW_VERSION"

# Step 3b: Remove local gateway service (gateway runs in Docker only)
echo "3b. Removing local gateway service (Docker handles this)..."
openclaw daemon uninstall 2>/dev/null || true
rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# Step 4: Rebuild and start gateway
echo "4. Rebuilding and starting gateway with new version..."
cd "$REPO_DIR"
docker compose build --no-cache
"$SCRIPT_DIR/start.sh"

echo ""
echo "=== Upgrade complete ==="
echo "OpenClaw upgraded to version $NEW_VERSION"