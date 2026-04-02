#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

echo "Restarting OpenClaw gateway..."
# Use 'up -d' instead of 'restart' so new volume mounts and config changes take effect
docker compose restart openclaw-gateway
echo "Done. Web UI: http://localhost:18789"
