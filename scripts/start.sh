#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_ROOT="${OPENCLAW_ROOT:-$HOME/openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenClaw Gateway Start ==="
echo ""

# Build options list: root dir first, then each subdirectory
options=("$OPENCLAW_ROOT (all repos)")
subdirs=()
while IFS= read -r -d '' dir; do
    name="$(basename "$dir")"
    options+=("$OPENCLAW_ROOT/$name")
    subdirs+=("$name")
done < <(find "$OPENCLAW_ROOT" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

echo "Choose workspace scope to mount into openclaw:"
echo ""
for i in "${!options[@]}"; do
    echo "  $((i+1)). ${options[$i]}"
done
echo ""

read -rp "Enter number [1]: " choice
choice="${choice:-1}"

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Strip the label suffix from option 1 (all repos)
if [ "$choice" -eq 1 ]; then
    selected_workspace="$OPENCLAW_ROOT"
else
    idx=$((choice - 1))
    selected_workspace="${options[$idx]}"
fi

echo ""
echo "Workspace: $selected_workspace"
echo ""

export OPENCLAW_WORKSPACE="$selected_workspace"

cd "$REPO_DIR"
docker compose up -d --build

echo ""
echo "OpenClaw gateway is running."
echo "  Web UI:   http://localhost:18789"
echo "  Logs:     scripts/logs.sh"
echo "  Shell:    scripts/shell.sh"
echo "  Stop:     scripts/stop.sh"
