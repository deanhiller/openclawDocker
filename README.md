# openclawDocker

Dockerized [OpenClaw](https://openclaw.ai) gateway for secure, isolated AI assistant access.

## What this gives you

- OpenClaw runs in a Docker container with access **only** to your chosen workspace
- Your Mac filesystem is fully protected — the container sees nothing else
- Full web access for OpenClaw's browser automation
- Pre-loaded config from `~/.openclaw` — no setup inside Docker
- Chrome automation connects to your Mac's Chrome (with existing logged-in sessions)

## Prerequisites

- Docker Desktop installed and running
- OpenClaw installed on your Mac (`npm install -g openclaw` or via [openclaw.ai](https://openclaw.ai))
- `~/.openclaw/` configured on your Mac (run `openclaw onboard` if not done yet)
- Repos cloned into `$HOME/openclaw/`

## Commands

```bash
scripts/start.sh          # Start gateway (prompts for workspace scope)
scripts/stop.sh           # Stop gateway
scripts/restart.sh        # Restart gateway
scripts/shell.sh          # Open bash shell inside the container
scripts/logs.sh           # Tail container logs
scripts/check-latest.sh   # Check for OpenClaw updates
scripts/upgrade.sh        # Upgrade OpenClaw to specified version

scripts/start-chrome.sh   # Launch dedicated Chrome with CDP for browser automation
```

## First-time setup

1. Install OpenClaw on your Mac and run `openclaw onboard`
2. Clone this repo
3. Run `scripts/start-chrome.sh` and log in to LinkedIn, Instagram, WhatsApp Web, Telegram Web, Djinni, Wellfound
4. Configure `~/.openclaw/openclaw.json` for browser CDP (see `docs/openclaw-config-notes.md`)
5. Run `scripts/start.sh` — pick your workspace scope
6. Open http://localhost:18789

## Upgrading OpenClaw

To upgrade OpenClaw to a new version:

1. Check for updates:
   ```bash
   ./scripts/check-latest.sh
   ```

2. Upgrade to latest version:
   ```bash
   LATEST=$(npm view openclaw version)
   ./scripts/upgrade.sh "$LATEST"
   ```

3. Or upgrade to a specific version:
   ```bash
   ./scripts/upgrade.sh 2026.4.5
   ```

The upgrade script will:
- Stop the gateway
- Update the VERSION file
- Upgrade your local OpenClaw CLI
- Rebuild and restart the gateway with the new version

## Security

- Container only accesses the mounted workspace directory
- Gateway port (18789) bound to localhost only — not exposed to LAN
- Chrome CDP port (9222) bound to localhost only
- No secrets in this repo — all credentials stay in `~/.openclaw/` on your Mac

See `docs/openclaw-config-notes.md` for detailed configuration.
