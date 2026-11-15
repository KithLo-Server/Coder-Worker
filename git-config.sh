#!/usr/bin/env sh

# Shared git environment setup for both the worker and shell containers.
# Sourced by each entrypoint after `set -eu`, so failures abort container start.

git config --global core.autocrlf input

if [ -n "${OPENCODE_SSH_KEY:-}" ]; then
    SSH_KEY_FILE="/root/.ssh/opencode_key"
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
    printf '%s' "$OPENCODE_SSH_KEY" > "$SSH_KEY_FILE"
    chmod 600 "$SSH_KEY_FILE"
    git config --global user.signingkey "$SSH_KEY_FILE"
    git config --global commit.gpgsign true
    git config --global gpg.format ssh
    git config --global core.sshCommand "ssh -i $SSH_KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
    unset OPENCODE_SSH_KEY
fi

if [ -n "${GIT_USER_NAME:-}" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "${GIT_USER_EMAIL:-}" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

# Keep GIT_USER_NAME and GIT_USER_EMAIL in the environment: the hook uses them
# to reject commits made with a different effective identity.
git config --global hook.verify-commit-identity.command /usr/local/bin/git-identity-hook
git config --global --replace-all hook.verify-commit-identity.event pre-commit
