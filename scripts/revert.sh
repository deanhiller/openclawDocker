#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenClaw Revert ==="
echo ""

# Check we have something to revert to
PREVIOUS_VERSION_FILE="$REPO_DIR/VERSION.previous"
if [ ! -f "$PREVIOUS_VERSION_FILE" ]; then
    echo "No VERSION.previous file found — nothing to revert to."
    exit 1
fi

PREVIOUS_VERSION=$(cat "$PREVIOUS_VERSION_FILE")
CURRENT_VERSION=$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "unknown")

echo "Reverting from $CURRENT_VERSION to $PREVIOUS_VERSION"
echo ""

# Step 1: Stop the gateway
echo "1. Stopping OpenClaw gateway..."
"$SCRIPT_DIR/stop.sh"

# Step 2: Restore previous Docker image if tagged
if docker image inspect openclaw-local:previous >/dev/null 2>&1; then
    echo "2. Restoring previous Docker image..."
    docker tag openclaw-local:previous openclaw-local:latest
    echo "   Restored openclaw-local:previous as openclaw-local:latest"
else
    echo "2. No previous image tag found — rebuilding from previous version..."
    echo "$PREVIOUS_VERSION" > "$REPO_DIR/VERSION"
    "$SCRIPT_DIR/build.sh"
fi

# Step 3: Restore VERSION file
echo "3. Restoring VERSION file..."
echo "$PREVIOUS_VERSION" > "$REPO_DIR/VERSION"
rm -f "$PREVIOUS_VERSION_FILE"

# Step 4: Downgrade local CLI
echo "4. Downgrading local OpenClaw CLI to $PREVIOUS_VERSION..."
npm install -g "openclaw@$PREVIOUS_VERSION"

echo ""
echo "=== Revert complete ==="
echo "OpenClaw reverted to $PREVIOUS_VERSION"
echo ""
echo "Run scripts/start.sh to start the gateway."
