FROM ghcr.io/kithlo-server/worker:latest

# Install OpenCode CLI + permission configuration
RUN npm install -g opencode-ai \
    && npm cache clean --force \
    && rm -rf /root/.npm \
    && mkdir -p /root/.config/opencode \
    && echo '{"permission": {"external_directory": "allow", "bash": "allow", "shell": "allow", "webfetch": "allow", "websearch": "allow"}}' > /root/.config/opencode/opencode.json

WORKDIR /workspace

COPY --chmod=0755 git-config.sh /usr/local/bin/git-config.sh
COPY --chmod=0755 worker-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
