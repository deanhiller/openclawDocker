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

# Copy version file and install OpenClaw
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

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node
WORKDIR /workspace

EXPOSE 18789 18790

CMD ["/entrypoint.sh"]
