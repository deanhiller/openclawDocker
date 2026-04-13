#!/usr/bin/env bash
# openclaw gateway binds to loopback (127.0.0.1:18789) — no pairing required.
# socat listens on 0.0.0.0:18790 so Docker can forward the port, then proxies to openclaw.
set -euo pipefail

# Install Claude Code native binary on first run (when the mount is empty).
# Subsequent runs reuse the persisted binary; auto-updates write to the same mount.
if [ ! -x "$HOME/.local/bin/claude" ]; then
  echo "Claude Code not found in mounted volume — installing native binary..."
  # Bootstrap: use the npm version (if present) or download directly
  npx @anthropic-ai/claude-code install 2>/dev/null \
    || curl -fsSL https://cli.claude.ai/install.sh | sh
  echo "Claude Code installed: $($HOME/.local/bin/claude --version)"
fi

socat TCP-LISTEN:18790,fork,reuseaddr TCP:127.0.0.1:18789 &

exec openclaw gateway
