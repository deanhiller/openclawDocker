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

# Install openclaw globally as root, then switch to node user
RUN npm install -g openclaw

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The node user (uid 1000) is already created by the node base image.
# ~/.openclaw will be bind-mounted from the host so all config/tokens are pre-loaded.

USER node
WORKDIR /workspace

EXPOSE 18789 18790

CMD ["/entrypoint.sh"]
