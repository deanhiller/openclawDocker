# OpenClaw Configuration Notes

All configuration lives at `~/.openclaw/openclaw.json` on your Mac.
Edit it there and restart the gateway (`scripts/restart.sh`) to apply changes.

## Browser Automation (CDP)

To connect OpenClaw to your Mac's Chrome instance:

1. Start Chrome with `scripts/start-chrome.sh`
2. Log in to all target sites in that Chrome window (one-time setup)
3. Add to `~/.openclaw/openclaw.json`:

```json
{
  "browser": {
    "enabled": true,
    "defaultProfile": "host-chrome",
    "profiles": {
      "host-chrome": {
        "type": "cdp",
        "url": "ws://host.docker.internal:9222"
      }
    }
  }
}
```

## Sites to Configure

Log in to these in the dedicated Chrome profile (`~/.openclaw-chrome-profile`):
- **LinkedIn** — job posting + message responses
- **Instagram** — DM responses
- **WhatsApp Web** (web.whatsapp.com) — message responses
- **Telegram Web** (web.telegram.org) — message responses
- **Djinni** (djinni.co) — job posting + candidate responses
- **Wellfound** (wellfound.com) — job posting + candidate responses

## Messaging Bridges (Real-time)

OpenClaw can connect directly to Telegram and WhatsApp via API bridges for
real-time message handling (no browser needed):

- **Telegram Bot API**: Create a bot via @BotFather, add token to openclaw.json
- **WhatsApp Bridge**: Uses WhatsApp Web session kept alive in the browser profile

For LinkedIn, Instagram, Djinni, Wellfound — browser automation is used since
they don't offer a public messaging API. OpenClaw polls periodically.

## Workspace Scoping

The Docker container mounts one workspace at a time (chosen at startup).
Inside the container, your repos are at `/workspace/`.

To switch repos: `scripts/stop.sh` → `scripts/start.sh` → pick a different scope.

## OAuth Token

Your `CLAUDE_CODE_OAUTH_TOKEN` (and other credentials) live in `~/.openclaw/`
on your Mac. They're automatically available inside the container via the
bind mount. Never put tokens in this git repo.
