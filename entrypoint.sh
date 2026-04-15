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

# Seed the nx platform-guard helper into the bind-mounted ~/openclaw/bin.
# Written from the image on every start so Mac + container stay in sync
# with whatever version the image was built with. The Mac side may also
# write the same file via baseNxMonorepo/scripts/build.sh — last-write-wins
# is fine because both sides copy identical canonical bytes.
if [ -f /opt/nx-guard/ensure-node-modules.sh ]; then
  mkdir -p "$HOME/openclaw/bin"
  if ! cmp -s /opt/nx-guard/ensure-node-modules.sh "$HOME/openclaw/bin/ensure-node-modules.sh" 2>/dev/null; then
    cp /opt/nx-guard/ensure-node-modules.sh "$HOME/openclaw/bin/ensure-node-modules.sh"
    chmod +x "$HOME/openclaw/bin/ensure-node-modules.sh"
    echo "Seeded nx-guard helper into $HOME/openclaw/bin/"
  fi
fi

# Resolve host.docker.internal to its IP every start — Chrome's DevTools rejects
# Host headers that aren't IPs or "localhost" (DNS rebinding protection), so we
# can't use the hostname directly in the Playwright MCP endpoint. The IP can
# change across Docker Desktop restarts, so re-resolve every time.
HOST_IP="$(getent ahostsv4 host.docker.internal 2>/dev/null | awk '/STREAM/ {print $1; exit}')"
if [ -z "$HOST_IP" ]; then
  echo "WARNING: could not resolve host.docker.internal — Playwright MCP will not work"
  HOST_IP="host.docker.internal"  # fall back, user may manually fix
fi
echo "Host IP resolved to: $HOST_IP"

# Write (or refresh) the Playwright MCP entry in ~/.claude.json.
# Runs every start so the endpoint always matches the current host IP.
if [ -f "$HOME/.claude.json" ]; then
  HOST_IP="$HOST_IP" node -e '
    const fs = require("fs");
    const path = process.env.HOME + "/.claude.json";
    const cfg = JSON.parse(fs.readFileSync(path, "utf8"));
    cfg.mcpServers = cfg.mcpServers || {};
    const existing = cfg.mcpServers.playwright;
    const desiredEndpoint = `http://${process.env.HOST_IP}:9223`;
    const needsUpdate = !existing
      || existing.env?.PLAYWRIGHT_MCP_CDP_ENDPOINT !== desiredEndpoint;
    if (needsUpdate) {
      cfg.mcpServers.playwright = {
        type: "stdio",
        command: "npx",
        args: ["@playwright/mcp@latest"],
        env: { PLAYWRIGHT_MCP_CDP_ENDPOINT: desiredEndpoint }
      };
      fs.writeFileSync(path, JSON.stringify(cfg, null, 2));
      console.log(`Playwright MCP endpoint set to ${desiredEndpoint}`);
    }
  '
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
