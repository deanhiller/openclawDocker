#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_DIR" | tr '[:upper:]' '[:lower:]')}"

cd "$REPO_DIR"

JQ_FILTER='
  .time + " [" +
  (.["_meta"].name as $name | try ($name | fromjson | .subsystem | split("/") | last) catch $name) + "] " +
  ((.["0"] // .["1"]) | if type == "string" then . else tojson end)
'

# Find the log file from inside the container (uses container UTC date)
LOG_FILE=$(docker compose exec openclaw-gateway sh -c 'ls /tmp/openclaw/openclaw-*.log 2>/dev/null | tail -1')
if [[ -z "$LOG_FILE" ]]; then
  echo "No log file found yet in container — is the gateway running?"
  exit 1
fi

if [[ "${1:-}" == "--less" ]]; then
  docker compose exec openclaw-gateway cat "$LOG_FILE" | jq -Rr ". as \$raw | try (fromjson | $JQ_FILTER) catch \$raw" | less
else
  docker compose exec openclaw-gateway tail -f "$LOG_FILE" | jq -Rr ". as \$raw | try (fromjson | $JQ_FILTER) catch \$raw"
fi
