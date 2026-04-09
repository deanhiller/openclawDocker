#!/usr/bin/env bash
set -euo pipefail

# Script to list OpenClaw agents with their workspaces
# Also shows which agents correspond to which project directories

echo "=== OpenClaw Agents ==="
echo ""

# Get agent list
openclaw agents list

echo ""
echo "=== Project Directory Mapping ==="
echo ""

# List project directories and their corresponding agent names
WORKSPACE_ROOT="/Users/deanhiller/openclaw"

echo "Project directories under $WORKSPACE_ROOT:"
echo ""

# Function to create agent name from path (same as in other scripts)
create_agent_name() {
    local path="$1"
    local relative_path="${path#$WORKSPACE_ROOT/}"
    
    if [ -z "$relative_path" ] || [ "$relative_path" = "$WORKSPACE_ROOT" ]; then
        echo "main"
        return
    fi
    
    local agent_name="${relative_path//\//_}"
    agent_name=$(echo "$agent_name" | sed 's/^_*//; s/_*$//' | tr '[:upper:]' '[:lower:]')
    echo "$agent_name"
}

# List first and second level directories
idx=1
while IFS= read -r -d '' dir; do
    dir_name=$(basename "$dir")
    
    # Skip hidden directories
    if [[ "$dir_name" == .* ]]; then
        continue
    fi
    
    agent_name=$(create_agent_name "$dir")
    echo "$idx. $dir_name/ → agent: $agent_name"
    idx=$((idx + 1))
    
    # List subdirectories
    while IFS= read -r -d '' subdir; do
        subdir_name=$(basename "$subdir")
        
        if [[ "$subdir_name" == .* ]]; then
            continue
        fi
        
        sub_agent_name=$(create_agent_name "$subdir")
        echo "   $dir_name/$subdir_name → agent: $sub_agent_name"
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z)
    
    echo ""
done < <(find "$WORKSPACE_ROOT" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)

echo ""
echo "=== Quick Start ==="
echo ""
echo "To start TUI for any project:"
echo "  cd ~/openclaw/personal/myProject && openclawTui.sh"