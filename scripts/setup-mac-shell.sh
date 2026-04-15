#!/usr/bin/env bash
# setup-mac-shell.sh — one-shot Mac host installer for the nx platform-guard.
#
# Run this from the Mac host (not inside the container) to:
#   1) copy ensure-node-modules.sh into ~/openclaw/bin/
#   2) install the pnpm/npx wrapper block into ~/.zshrc
#
# Inside the Docker container the same setup happens automatically:
#   - Dockerfile bakes the wrapper block into ~/.bashrc
#   - entrypoint.sh seeds ~/openclaw/bin/ensure-node-modules.sh via the
#     ~/openclaw bind mount
#
# Idempotent — safe to re-run. Updates in place using sentinel markers.
#
# Opt out: CLAUDE_NO_SHELL_SETUP=1 ./scripts/setup-mac-shell.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -n "${CLAUDE_NO_SHELL_SETUP:-}" ]; then
    echo "CLAUDE_NO_SHELL_SETUP set — skipping."
    exit 0
fi

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS only. Inside the container the guard is"
    echo "already installed by the Docker image."
    exit 0
fi

BIN_DIR="$HOME/openclaw/bin"
SNIPPET_SRC="$REPO_DIR/nx-guard-bashrc.sh"

# Files copied into ~/openclaw/bin/ — the helper plus the pnpm/npx shims that
# every subprocess needs to find on PATH.
BIN_FILES=(
    "$REPO_DIR/ensure-node-modules.sh"
    "$REPO_DIR/shims/pnpm"
    "$REPO_DIR/shims/npx"
)

for f in "$SNIPPET_SRC" "${BIN_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found — openclawDocker1 appears incomplete." >&2
        exit 1
    fi
done

mkdir -p "$BIN_DIR"

# Copy / refresh helper + shims.
for src in "${BIN_FILES[@]}"; do
    dst="$BIN_DIR/$(basename "$src")"
    if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
        cp "$src" "$dst"
        chmod +x "$dst"
        echo "🔧 Installed $dst"
    fi
done

# Pick target rc file (zsh is macOS default since 10.15).
RC="$HOME/.zshrc"
[ -f "$RC" ] || RC="$HOME/.bash_profile"

BEGIN="# >>> nx platform-guard (managed by openclawDocker1 setup-mac-shell.sh) >>>"
END="# <<< nx platform-guard <<<"
SNIPPET="$(cat "$SNIPPET_SRC")"
DESIRED="${BEGIN}
${SNIPPET}
${END}"

touch "$RC"

CURRENT_BLOCK=""
if grep -qF "$BEGIN" "$RC" 2>/dev/null; then
    CURRENT_BLOCK="$(awk -v b="$BEGIN" -v e="$END" '
        $0 == b { inblk=1 }
        inblk   { print }
        $0 == e { inblk=0 }
    ' "$RC")"
fi

if [ "$CURRENT_BLOCK" = "$DESIRED" ]; then
    echo "✅ nx-guard block already up to date in $RC"
    exit 0
fi

cp "$RC" "$RC.bak-$(date +%Y%m%d-%H%M%S)"

if grep -qF "$BEGIN" "$RC"; then
    awk -v b="$BEGIN" -v e="$END" -v new="$DESIRED" '
        $0 == b { print new; inblk=1; next }
        inblk && $0 == e { inblk=0; next }
        !inblk { print }
    ' "$RC" > "$RC.tmp"
    mv "$RC.tmp" "$RC"
    echo "🔧 Updated nx-guard block in $RC"
else
    {
        echo ""
        echo "$DESIRED"
    } >> "$RC"
    echo "🔧 Installed nx-guard block in $RC"
fi

echo ""
echo "Done. Open a new terminal or run:"
echo "  source $RC"
