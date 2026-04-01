#!/usr/bin/env bash
# openclaw gateway binds to loopback (127.0.0.1:18789) — no pairing required.
# socat listens on 0.0.0.0:18790 so Docker can forward the port, then proxies to openclaw.
set -euo pipefail

socat TCP-LISTEN:18790,fork,reuseaddr TCP:127.0.0.1:18789 &

exec openclaw gateway
