FROM node:24-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    python3 \
    ca-certificates \
    socat \
    && rm -rf /var/lib/apt/lists/*

# Copy version files and install OpenClaw at build time (runs as root → /usr/local/bin)
COPY VERSION /tmp/VERSION
RUN OPENCLAW_VERSION=$(cat /tmp/VERSION) && \
    npm install -g openclaw@${OPENCLAW_VERSION}

# Set the node user's home to match the Mac user's home directory so that
# ~/.openclaw inside the container = $HOME/.openclaw on the Mac — identical paths,
# single volume mount, no path translation issues.
ARG MAC_HOME
RUN test -n "${MAC_HOME}" || { echo "ERROR: MAC_HOME build arg is required (pass via docker-compose or --build-arg MAC_HOME=\$HOME)"; exit 1; } && \
    usermod -d ${MAC_HOME} node && \
    mkdir -p ${MAC_HOME} && \
    chown node:node ${MAC_HOME}

# Shell config: prompt and claude alias
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ${MAC_HOME}/.bashrc && \
    echo 'export PS1="Docker:\\w\\$ "' >> ${MAC_HOME}/.bashrc && \
    echo "alias claude='claude --dangerously-skip-permissions'" >> ${MAC_HOME}/.bashrc && \
    echo 'export HOST_IP="$(getent hosts host.docker.internal 2>/dev/null | awk '"'"'{print $1}'"'"')"' >> ${MAC_HOME}/.bashrc && \
    chown node:node ${MAC_HOME}/.bashrc

# Embed git hash so the image can be queried for its source commit
ARG GIT_HASH=unknown
RUN echo "${GIT_HASH}" > /etc/git-hash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Install Claude Code native binary to a staging dir inside the image.
# The real ~/.local is volume-mounted at runtime (so updates persist), so we
# stage here and let the entrypoint seed the mount on first run.
RUN mkdir -p /opt/claude-stage/.local
ENV HOME_BACKUP=${MAC_HOME}
ENV HOME=/opt/claude-stage
COPY CLAUDE_VERSION /tmp/CLAUDE_VERSION
RUN CLAUDE_VERSION=$(cat /tmp/CLAUDE_VERSION | tr -d '[:space:]') && \
    npx "@anthropic-ai/claude-code@${CLAUDE_VERSION}" install
ENV HOME=${HOME_BACKUP}

USER node
WORKDIR ${MAC_HOME}

EXPOSE 18789 18790

CMD ["/entrypoint.sh"]
