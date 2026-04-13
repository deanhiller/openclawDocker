#!/usr/bin/env bash
# openclaw gateway binds to loopback (127.0.0.1:18789) — no pairing required.
# socat listens on 0.0.0.0:18790 so Docker can forward the port, then proxies to openclaw.
set -euo pipefail

# Seed the mounted ~/.local from the staged build-time install (first run only).
# After this, claude auto-updates write directly to the mount and persist.
if [ ! -x "$HOME/.local/bin/claude" ]; then
  echo "Seeding Claude Code from image into mounted volume..."
  cp -a /opt/claude-stage/.local/. "$HOME/.local/"
  echo "Claude Code ready: $($HOME/.local/bin/claude --version)"
fi

# Report the git hash this image was built from; warn if it's a dev build
GIT_HASH=$(cat /etc/git-hash 2>/dev/null || echo "unknown")
echo "Image built from git hash: $GIT_HASH"
if [[ "$GIT_HASH" == *-dev ]]; then
  echo "WARNING: this is dev only, please commit changes and rebuild the real image"
fi

socat TCP-LISTEN:18790,fork,reuseaddr TCP:127.0.0.1:18789 &

# Run openclaw gateway but keep the container alive if it crashes, so you can
# still shell in and use claude. Retry every 10 seconds.
while true; do
  echo "Starting openclaw gateway..."
  openclaw gateway || echo "openclaw gateway exited with code $? — retrying in 10s..."
  sleep 10
done
