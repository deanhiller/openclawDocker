#!/usr/bin/env bash
set -euo pipefail

# OpenClaw TUI Launcher
# Automatically detects project based on current directory
# Warns when using root agent

# Configuration
WORKSPACE_ROOT="/Users/deanhiller/openclaw"

# Check if current directory is within the workspace
is_in_workspace() {
    local current_dir="$(pwd)"
    [[ "$current_dir" == "$WORKSPACE_ROOT"* ]]
}

# Function to create agent name from path
create_agent_name() {
    local path="$1"

    # Remove workspace root prefix
    local relative_path="${path#$WORKSPACE_ROOT/}"
    
    # If it's the root workspace, return "main"
    if [ -z "$relative_path" ] || [ "$relative_path" = "$WORKSPACE_ROOT" ] || [ "$relative_path" = "." ]; then
        echo "main"
        return
    fi
    
    # Replace slashes with underscores
    local agent_name="${relative_path//\//_}"
    
    # Remove any leading/trailing underscores and make it lowercase
    agent_name=$(echo "$agent_name" | sed 's/^_*//; s/_*$//' | tr '[:upper:]' '[:lower:]')
    
    echo "$agent_name"
}

# Function to ensure agent exists
ensure_agent() {
    local path="$1"
    local agent_name="$2"

    # Check if agent exists
    if openclaw agents list 2>/dev/null | grep -q "^- $agent_name"; then
        echo "✓ Using existing agent: $agent_name" >&2

        # Verify workspace matches
        local agent_info
        agent_info=$(openclaw agents list 2>/dev/null | grep -A2 "^- $agent_name" || true)
        if echo "$agent_info" | grep -q "Workspace:"; then
            local current_ws
            current_ws=$(echo "$agent_info" | grep "Workspace:" | sed 's/.*Workspace: //')
            # Expand tilde to home directory for consistent comparison
            current_ws="${current_ws/#\~/$HOME}"
            if [ "$current_ws" != "$path" ]; then
                echo "⚠ Workspace mismatch: agent uses '$current_ws'" >&2
                echo "   Updating agent workspace..." >&2
                openclaw agents add "$agent_name" --workspace "$path" --non-interactive 2>/dev/null || true
            fi
        fi
    else
        echo "Creating agent: $agent_name for $path" >&2
        if openclaw agents add "$agent_name" --workspace "$path" --non-interactive 2>/dev/null; then
            echo "✓ Agent created" >&2
        else
            echo "⚠ Could not create agent, using default" >&2
            agent_name="main"
        fi
    fi

    echo "$agent_name"
}

# Confirm root agent usage
confirm_root_agent() {
    local root_path="$1"
    
    echo ""
    echo "⚠️  WARNING: You are at the workspace root!"
    echo ""
    echo "You're about to use the ROOT agent (main) which has access to:"
    echo "  ALL projects under $root_path"
    echo ""
    echo "This agent can manipulate files across ALL projects."
    echo ""
    echo "Recommended: Navigate to a specific project directory instead."
    echo ""
    
    while true; do
        read -rp "Are you sure you want to use the ROOT agent? (yes/no): " confirm
        
        case "$confirm" in
            [Yy]|[Yy][Ee][Ss])
                echo ""
                echo "Proceeding with ROOT agent..."
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo ""
                echo "Operation cancelled."
                echo "Navigate to a specific project directory and run 'ocl' again."
                exit 0
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# Main function
main() {
    if ! is_in_workspace; then
        echo "❌ Error: Not in an OpenClaw workspace"
        echo ""
        echo "You must be in a directory under:"
        echo "  - $WORKSPACE_ROOT"
        echo ""
        echo "Current directory: $(pwd)"
        exit 1
    fi

    # Get current directory
    local current_dir="$(pwd)"
    local project_path="$current_dir"
    local workspace_path="$current_dir"

    # Check if we're at the root
    local at_root=false
    if [ "$project_path" = "$WORKSPACE_ROOT" ]; then
        at_root=true
    fi
    
    # If at root, ask for confirmation
    if [ "$at_root" = true ]; then
        echo "=== OpenClaw TUI (Docker) ==="
        echo "Current dir: $current_dir (WORKSPACE ROOT)"
        echo "Docker project: $project_path"
        echo "Docker workspace: $workspace_path"
        echo ""
        
        confirm_root_agent "$project_path"
        
        # Use main agent for root
        local agent_name="main"
        echo "Agent: $agent_name (ROOT agent - access to ALL projects)"
        echo ""
        
        # Ensure agent exists
        agent_name=$(ensure_agent "$workspace_path" "$agent_name")

        # Start TUI
        echo ""
        echo "Starting OpenClaw TUI with ROOT agent: $agent_name"
        echo "Session: agent:main:$agent_name"
        echo ""
        
        openclaw tui --session "agent:main:$agent_name"
        return
    fi
    
    # Otherwise, use detected project automatically
    echo "=== OpenClaw TUI (Docker) ==="
    echo "Current dir: $current_dir"
    echo "Docker project: $project_path"
    echo "Docker workspace: $workspace_path"
    echo ""
    
    # Create agent name
    local agent_name
    agent_name=$(create_agent_name "$project_path")
    
    echo "Agent: $agent_name"
    echo ""
    
    # Ensure agent exists
    agent_name=$(ensure_agent "$workspace_path" "$agent_name")

    # Start TUI
    echo ""
    echo "Starting OpenClaw TUI with agent: $agent_name"
    echo "Session: agent:main:$agent_name"
    echo ""
    
    openclaw tui --session "agent:main:$agent_name"
}

# If a path is provided as argument, use it directly
if [ $# -gt 0 ]; then
    if [ -d "$1" ]; then
        echo "=== OpenClaw TUI (Docker) for: $1 ==="
        echo ""
        
        # Ensure absolute path
        if [[ "$1" != /* ]]; then
            target_path="$(cd "$1" && pwd)"
        else
            target_path="$1"
        fi
        
        local workspace_path="$target_path"

        # Check if this is the root
        if [ "$target_path" = "$WORKSPACE_ROOT" ]; then
            echo "⚠️  WARNING: You specified the workspace root!"
            echo "This will use the ROOT agent (main) with access to ALL projects."
            echo ""
            while true; do
                read -rp "Are you sure? (yes/no): " confirm
                case "$confirm" in
                    [Yy]|[Yy][Ee][Ss])
                        break
                        ;;
                    [Nn]|[Nn][Oo])
                        echo "Operation cancelled."
                        exit 0
                        ;;
                    *)
                        echo "Please answer yes or no."
                        ;;
                esac
            done
        fi
        
        # Create agent name
        local agent_name
        agent_name=$(create_agent_name "$target_path")
        agent_name=$(ensure_agent "$workspace_path" "$agent_name")

        echo ""
        echo "Starting TUI with agent: $agent_name"
        echo ""
        
        openclaw tui --session "agent:main:$agent_name"
    else
        echo "Error: Directory does not exist: $1"
        exit 1
    fi
else
    # No arguments, auto-detect from current directory
    main "$@"
fi