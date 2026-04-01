#!/usr/bin/env bash
# Start openclaw gateway (binds to 127.0.0.1:18789 — loopback only, no pairing required)
# then use socat to proxy 0.0.0.0:18790 → 127.0.0.1:18789 so Docker can forward the port.
# docker-compose maps host 127.0.0.1:18789 → container 18790.

set -euo pipefail

# Start socat proxy in background: listens on all interfaces :18790, forwards to loopback :18789
socat TCP-LISTEN:18790,fork,reuseaddr TCP:127.0.0.1:18789 &

# Start openclaw gateway (foreground)
exec openclaw gateway
