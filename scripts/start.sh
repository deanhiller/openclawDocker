#!/usr/bin/env bash
set -euo pipefail

OPENCLAW_ROOT="${OPENCLAW_ROOT:-$HOME/openclaw}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== OpenClaw Gateway Start ==="
echo ""

# Build flat paths array and display menu with visual grouping
options_paths=()
options_paths+=("$OPENCLAW_ROOT")

echo "Choose workspace scope to mount into openclaw:"
echo ""
echo "  1. $OPENCLAW_ROOT (all repos)"

idx=2
while IFS= read -r -d '' group_dir; do
    group_name="$(basename "$group_dir")"

    # Collect subdirectories of this group
    group_subdirs=()
    while IFS= read -r -d '' project_dir; do
        group_subdirs+=("$project_dir")
    done < <(find "$group_dir" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z)

    if [ "${#group_subdirs[@]}" -gt 0 ]; then
        echo ""
        echo "  ${group_name}/"
        options_paths+=("$group_dir")
        echo "  $idx.   $group_dir (all ${group_name} repos)"
        idx=$((idx + 1))
        for project_dir in "${group_subdirs[@]}"; do
            options_paths+=("$project_dir")
            echo "  $idx.   $project_dir"
            idx=$((idx + 1))
        done
    else
        # Leaf-level group (no sub-projects) — treat as a single entry
        echo ""
        options_paths+=("$group_dir")
        echo "  $idx. $group_dir"
        idx=$((idx + 1))
    fi
done < <(find "$OPENCLAW_ROOT" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

echo ""

read -rp "Enter number [1]: " choice
choice="${choice:-1}"

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options_paths[@]}" ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

selected_workspace="${options_paths[$((choice - 1))]}"

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
