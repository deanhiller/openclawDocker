#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$SCRIPT_DIR")"

JQ_FILTER='
  .time + " [" +
  (.["_meta"].name | try (fromjson | .subsystem | split("/") | last) catch .) + "] " +
  (.["1"] | if type == "string" then . else tojson end)
'

# Find the log file from inside the container (uses container UTC date)
LOG_FILE=$(docker exec openclaw-gateway sh -c 'ls /tmp/openclaw/openclaw-*.log 2>/dev/null | tail -1')
if [[ -z "$LOG_FILE" ]]; then
  echo "No log file found yet in container — is the gateway running?"
  exit 1
fi

if [[ "${1:-}" == "--less" ]]; then
  docker exec openclaw-gateway cat "$LOG_FILE" | jq -r "$JQ_FILTER" | less
else
  docker exec openclaw-gateway tail -f "$LOG_FILE" | jq -r "$JQ_FILTER"
fi
