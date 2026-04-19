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

# Seed the nx platform-guard helper + pnpm/npx shims into the bind-mounted
# ~/openclaw/bin. Written from the image on every start so Mac + container
# stay in sync with whatever version the image was built with. The Mac side
# may also write the same files via setup-mac-shell.sh — last-write-wins is
# fine because both sides copy identical canonical bytes.
mkdir -p "$HOME/openclaw/bin"
for src in /opt/nx-guard/ensure-node-modules.sh /opt/nx-guard/pnpm /opt/nx-guard/npx; do
  [ -f "$src" ] || continue
  dst="$HOME/openclaw/bin/$(basename "$src")"
  if ! cmp -s "$src" "$dst" 2>/dev/null; then
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "Seeded $(basename "$src") into $HOME/openclaw/bin/"
  fi
done

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
#
# Opt out by setting OPENCLAW_START_GATEWAY=0 (scripts/start.sh prompt controls this).
# When disabled, the container stays up so you can shell in and run claude
# without paying the gateway's memory/CPU cost.
# Sentinel file honored by the loop below. If present, the gateway is not
# (re)started and the container just stays alive. scripts/gateway-stop.sh
# creates this file and kills the running gateway; scripts/gateway-start.sh
# removes it. Kept in /tmp (world-writable) because the container runs as
# the non-root `node` user. /tmp is cleared on container restart, so state
# never persists across a compose up/down.
GATEWAY_DISABLE_FLAG="/tmp/openclaw-gateway-disabled"
if [ "${OPENCLAW_START_GATEWAY:-1}" = "0" ]; then
  touch "$GATEWAY_DISABLE_FLAG"
  echo "OPENCLAW_START_GATEWAY=0 — gateway process will not launch."
  echo "Container is up; shell in with scripts/shell.sh and run claude normally."
  echo "Start the gateway later (no container restart): scripts/gateway-start.sh"
fi

while true; do
  if [ -e "$GATEWAY_DISABLE_FLAG" ]; then
    sleep 5
    continue
  fi
  echo "Starting openclaw gateway..."
  openclaw gateway || echo "openclaw gateway exited with code $? — retrying in 10s..."
  sleep 10
done
