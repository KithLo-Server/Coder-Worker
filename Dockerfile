FROM ghcr.io/kithlo-server/worker:latest

# Native config-based Git hooks require Git 2.54 or newer.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends git=1:2.56.1-0ppa1~ubuntu26.04.1 \
    && apt-get purge -y --auto-remove software-properties-common \
    && rm -rf /var/lib/apt/lists/* \
    && git --version

# Install OpenCode CLI + permission configuration
RUN npm install -g opencode-ai \
    && npm cache clean --force \
    && rm -rf /root/.npm \
    && mkdir -p /root/.config/opencode \
    && echo '{"permission": {"external_directory": "allow", "bash": "allow", "shell": "allow", "webfetch": "allow", "websearch": "allow"}}' > /root/.config/opencode/opencode.json

COPY AGENTS.md /root/.config/opencode/AGENTS.md

WORKDIR /workspace

COPY --chmod=0755 git-config.sh /usr/local/bin/git-config.sh
COPY --chmod=0755 git-identity-hook.sh /usr/local/bin/git-identity-hook
COPY --chmod=0755 worker-entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
