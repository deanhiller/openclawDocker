#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

echo "Entering shell inside openclaw-gateway container..."
echo "(Type 'exit' to leave)"
echo ""
docker compose exec openclaw-gateway /bin/bash
