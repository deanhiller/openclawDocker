#!/usr/bin/env bash
# ensure-node-modules.sh — idempotent platform-aware node_modules guard.
#
# Used in two ways:
#   1) Sourced by scripts/build.sh — build.sh reuses detect_platform,
#      swap_node_modules, check_and_install.
#   2) Invoked directly by the pnpm/npx shell wrappers:
#         ensure-node-modules.sh <project-root>
#      Fast-path exits silently when node_modules is already correct for
#      this platform and the lockfile hash matches.
set -euo pipefail

# Strip the shim directory from PATH so pnpm/npx calls from this script
# find the real binaries, not the shim. Replaces the old NX_GUARD_SKIP env var.
_strip_shim_from_path() {
    local shim_dir
    shim_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PATH=$(printf ':%s:' "$PATH" | sed "s|:${shim_dir}:|:|g; s|^:||; s|:$||")
    export PATH
}

detect_platform() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"
    case "$os-$arch" in
        Darwin-arm64)  echo "mac" ;;
        Darwin-x86_64) echo "mac_x64" ;;
        Linux-aarch64) echo "linux" ;;
        Linux-x86_64)  echo "linux_x64" ;;
        *)             echo "unknown_${os}_${arch}" ;;
    esac
}

compute_lockfile_hash() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum pnpm-lock.yaml | awk '{print $1}'
    else
        shasum -a 256 pnpm-lock.yaml | awk '{print $1}'
    fi
}

ensure_gitignore() {
    for ignore_file in .gitignore .nxignore; do
        if [ -f "$ignore_file" ]; then
            if ! grep -q "node_modules_" "$ignore_file" 2>/dev/null; then
                {
                    echo ""
                    echo "# Platform-specific node_modules backups"
                    echo "node_modules_*/"
                } >> "$ignore_file"
                echo "📝 Added node_modules_*/ to $ignore_file"
            fi
        fi
    done
}

# Swap node_modules to match $PLATFORM. Requires PLATFORM + NM_DIR + NM_PLATFORM in env.
swap_node_modules() {
    _strip_shim_from_path
    ensure_gitignore

    if [ -f "$NM_DIR/.platform" ] && [ "$(cat "$NM_DIR/.platform")" = "$PLATFORM" ]; then
        return 0
    fi

    if [ -d "$NM_DIR" ]; then
        if [ -f "$NM_DIR/.platform" ]; then
            local old_platform old_nm
            old_platform="$(cat "$NM_DIR/.platform")"
            old_nm="${NM_DIR}_${old_platform}"
            echo "📦 Saving current node_modules as ${old_nm}/"
            [ -d "$old_nm" ] && rm -rf "$old_nm"
            mv "$NM_DIR" "$old_nm"
        else
            echo "📦 Saving unlabeled node_modules as ${NM_DIR}_unknown/"
            [ -d "${NM_DIR}_unknown" ] && rm -rf "${NM_DIR}_unknown"
            mv "$NM_DIR" "${NM_DIR}_unknown"
        fi
    fi

    if [ -d "$NM_PLATFORM" ]; then
        echo "♻️  Restoring cached ${NM_PLATFORM}/ for $PLATFORM"
        mv "$NM_PLATFORM" "$NM_DIR"
    else
        echo "🔨 No cached node_modules for $PLATFORM — running pnpm install..."
        pnpm install --no-frozen-lockfile --config.confirmModulesPurge=false
        echo "$PLATFORM" > "$NM_DIR/.platform"
        compute_lockfile_hash > "$NM_DIR/.lockfile-hash"
        return 0
    fi

    echo "$PLATFORM" > "$NM_DIR/.platform"
    [ -f "$NM_DIR/.lockfile-hash" ] || compute_lockfile_hash > "$NM_DIR/.lockfile-hash"
}

# Reinstall if pnpm-lock.yaml changed since last install on this platform.
check_and_install() {
    _strip_shim_from_path
    local current_hash stored_hash
    current_hash="$(compute_lockfile_hash)"

    if [ -f "$NM_DIR/.lockfile-hash" ]; then
        stored_hash="$(cat "$NM_DIR/.lockfile-hash")"
    else
        stored_hash=""
    fi

    if [ "$current_hash" = "$stored_hash" ]; then
        return 0
    fi

    echo "🔨 Lockfile changed — running pnpm install..."
    pnpm install --no-frozen-lockfile --config.confirmModulesPurge=false
    compute_lockfile_hash > "$NM_DIR/.lockfile-hash"
    echo "$PLATFORM" > "$NM_DIR/.platform"
}

# Fast-path guard: silent no-op when platform + lockfile already match.
# Called by the pnpm/npx shell wrappers with the project root as $1.
guard_project() {
    local root="$1"
    _strip_shim_from_path
    cd "$root"

    [ -f package.json ] || return 0
    [ -f pnpm-lock.yaml ] || return 0

    PLATFORM="$(detect_platform)"
    NM_DIR="node_modules"
    NM_PLATFORM="${NM_DIR}_${PLATFORM}"

    # Fast path — silent exit when already correct.
    if [ -f "$NM_DIR/.platform" ] && [ "$(cat "$NM_DIR/.platform")" = "$PLATFORM" ] \
       && [ -f "$NM_DIR/.lockfile-hash" ] \
       && [ "$(cat "$NM_DIR/.lockfile-hash")" = "$(compute_lockfile_hash)" ]; then
        return 0
    fi

    echo "🔍 nx-guard: $root needs attention (platform=$PLATFORM)"
    swap_node_modules
    check_and_install
}

# When invoked as a script (not sourced), act as the guard.
# Detects sourcing via BASH_SOURCE comparison.
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
    if [ $# -ne 1 ]; then
        echo "Usage: $0 <project-root>" >&2
        exit 2
    fi
    guard_project "$1"
fi
