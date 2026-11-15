#!/usr/bin/env sh

set -eu

if [ -n "${GOOGLE_APPLICATION_CREDENTIALS_JSON:-}" ]; then
    GOOGLE_APPLICATION_CREDENTIALS="/root/.gcp-credentials.json"
    printf '%s' "$GOOGLE_APPLICATION_CREDENTIALS_JSON" > "$GOOGLE_APPLICATION_CREDENTIALS"
    chmod 600 "$GOOGLE_APPLICATION_CREDENTIALS"
    unset GOOGLE_APPLICATION_CREDENTIALS_JSON
fi

. /usr/local/bin/git-config.sh

sleep infinity
