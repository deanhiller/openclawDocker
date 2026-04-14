FROM node:24-bookworm

# ---------------- Stable foundation ----------------

RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    python3 \
    ca-certificates \
    socat \
    && rm -rf /var/lib/apt/lists/*

# MAC_HOME is declared early — the claude install below references it via
# HOME_BACKUP. Value = $HOME on the Mac, stable, so this never invalidates.
ARG MAC_HOME
RUN test -n "${MAC_HOME}" || { echo "ERROR: MAC_HOME build arg is required (pass via docker-compose or --build-arg MAC_HOME=\$HOME)"; exit 1; }

# ---------------- Expensive version-pinned installs ----------------
# These are the costly layers. Nothing above them changes during dev, and
# nothing below them is referenced here — so they stay cached until VERSION
# or CLAUDE_VERSION is intentionally bumped.

# OpenClaw (runs as root → /usr/local/bin)
COPY VERSION /tmp/VERSION
RUN OPENCLAW_VERSION=$(cat /tmp/VERSION) && \
    npm install -g openclaw@${OPENCLAW_VERSION}

# Claude Code native binary → staged to /opt/claude-stage, seeded to
# the mounted ~/.local at runtime via entrypoint.sh.
RUN mkdir -p /opt/claude-stage/.local
ENV HOME_BACKUP=${MAC_HOME}
ENV HOME=/opt/claude-stage
COPY CLAUDE_VERSION /tmp/CLAUDE_VERSION
RUN CLAUDE_VERSION=$(cat /tmp/CLAUDE_VERSION | tr -d '[:space:]') && \
    npx "@anthropic-ai/claude-code@${CLAUDE_VERSION}" install
ENV HOME=${HOME_BACKUP}

# ---------------- User & shell setup (stable, cheap) ----------------
# Moved BELOW installs so edits here don't invalidate the expensive layers.

# Point node user's home at MAC_HOME so host/container paths match exactly.
RUN usermod -d ${MAC_HOME} node && \
    mkdir -p ${MAC_HOME} && \
    chown node:node ${MAC_HOME}

# Shell config: prompt, aliases, host-ip helper.
# Edits here (new aliases, new env vars) are cheap — only re-runs the layers
# below, not the installs above.
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${MAC_HOME}/.bashrc && \
    echo 'export PS1="Docker:\\w\\$ "' >> ${MAC_HOME}/.bashrc && \
    echo "alias claude='claude --dangerously-skip-permissions'" >> ${MAC_HOME}/.bashrc && \
    echo 'export HOST_IP="$(getent hosts host.docker.internal 2>/dev/null | awk '"'"'{print $1}'"'"')"' >> ${MAC_HOME}/.bashrc && \
    chown node:node ${MAC_HOME}/.bashrc

# ---------------- High-churn layers (cheap, always last) ----------------

# entrypoint.sh — edited frequently during dev
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Git hash — changes every commit and every dirty-state toggle from build.sh
ARG GIT_HASH=unknown
RUN echo "${GIT_HASH}" > /etc/git-hash

# ---------------- Image metadata ----------------
USER node
WORKDIR ${MAC_HOME}

EXPOSE 18789 18790

CMD ["/entrypoint.sh"]
