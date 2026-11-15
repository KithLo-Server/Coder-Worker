#!/bin/sh

set -eu

# Enforce that commits use the identity supplied through GIT_USER_NAME and
# GIT_USER_EMAIL. Each variable is enforced independently; a variable that is
# unset or empty is ignored.

expected_name="${GIT_USER_NAME:-}"
expected_email="${GIT_USER_EMAIL:-}"

[ -n "$expected_name$expected_email" ] || exit 0

verify_ident() {
    label="$1"
    ident="$2"

    actual_name="${ident%% <*}"
    actual_email="${ident#*<}"
    actual_email="${actual_email%%>*}"

    mismatch=0
    if [ -n "$expected_name" ] && [ "$actual_name" != "$expected_name" ]; then
        printf 'error: refusing commit: %s name "%s" does not match GIT_USER_NAME "%s"\n' \
            "$label" "$actual_name" "$expected_name" >&2
        mismatch=1
    fi
    if [ -n "$expected_email" ] && [ "$actual_email" != "$expected_email" ]; then
        printf 'error: refusing commit: %s email "%s" does not match GIT_USER_EMAIL "%s"\n' \
            "$label" "$actual_email" "$expected_email" >&2
        mismatch=1
    fi

    return "$mismatch"
}

author_ident=$(git var GIT_AUTHOR_IDENT)
committer_ident=$(git var GIT_COMMITTER_IDENT)

status=0
verify_ident author "$author_ident" || status=1
verify_ident committer "$committer_ident" || status=1

exit "$status"
