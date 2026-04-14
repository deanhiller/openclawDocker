#!/usr/bin/env bash
# Launches a dedicated Chrome instance with Chrome DevTools Protocol (CDP) enabled.
# OpenClaw inside Docker connects to this via host.docker.internal:9223
# to automate LinkedIn, Instagram, WhatsApp Web, Telegram Web, Djinni, Wellfound, etc.
#
# Port 9223 (not the default 9222) avoids collision with the user's main Chrome /
# claude-in-chrome extension / host-side Playwright, which all default to 9222.
#
# This uses a SEPARATE Chrome profile (~/.openclaw-chrome-profile) so your
# normal Chrome session is unaffected. Log in to each site once and they stay logged in.
set -euo pipefail

CHROME_PROFILE="${HOME}/.openclaw-chrome-profile"
CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

if [ ! -f "$CHROME_BIN" ]; then
    echo "Error: Google Chrome not found at: $CHROME_BIN"
    echo "Install Chrome or update the CHROME_BIN path in this script."
    exit 1
fi

echo "Starting Chrome with CDP on port 9223..."
echo "Profile: $CHROME_PROFILE"
echo ""
echo "On first run: log in to LinkedIn, Instagram, WhatsApp Web, Telegram Web,"
echo "Djinni, and Wellfound inside this Chrome window."
echo ""
echo "OpenClaw + Docker Claude connect via: host.docker.internal:9223"
echo "(Configure in ~/.openclaw/openclaw.json — see docs/openclaw-config-notes.md)"
echo ""
echo "Press Ctrl+C to stop Chrome."
echo ""

"$CHROME_BIN" \
    --remote-debugging-port=9223 \
    --remote-debugging-address=127.0.0.1 \
    --user-data-dir="$CHROME_PROFILE" \
    --no-first-run \
    --no-default-browser-check \
    2>/dev/null
