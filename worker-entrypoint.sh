#!/usr/bin/env sh

set -eu

if [ -n "${GOOGLE_APPLICATION_CREDENTIALS_JSON:-}" ]; then
    GOOGLE_APPLICATION_CREDENTIALS="/root/.gcp-credentials.json"
    printf '%s' "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > "$GOOGLE_APPLICATION_CREDENTIALS"
    chmod 600 "$GOOGLE_APPLICATION_CREDENTIALS"
    unset GOOGLE_APPLICATION_CREDENTIALS_JSON
fi

if [ -n "${OPENCODE_INSTRUCTION:-}" ]; then
    mkdir -p /root/.config/opencode
    printf '%s\n' "$OPENCODE_INSTRUCTION" > /root/.config/opencode/AGENTS.md
    unset OPENCODE_INSTRUCTION
fi

. /usr/local/bin/git-config.sh

sleep infinity
