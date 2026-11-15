#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
hook="$repo_root/git-identity-hook.sh"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

export HOME="$tmp/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$HOME/.gitconfig"
export GIT_AUTHOR_DATE='2020-01-01T00:00:00+0000'
export GIT_COMMITTER_DATE='2020-01-01T00:00:00+0000'

git config --global commit.gpgsign false
git config --global init.defaultBranch main
git config --global hook.identity-test.command "$hook"
git config --global hook.identity-test.event pre-commit

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf 'ok - %s\n' "$*"
}

clear_identity_env() {
    unset GIT_USER_NAME GIT_USER_EMAIL \
        GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL \
        GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
}

make_repo() {
    dir="$tmp/repo"
    rm -rf "$dir"
    mkdir -p "$dir"
    git -C "$dir" init -q
    git -C "$dir" config user.name Alice
    git -C "$dir" config user.email alice@example.com
    printf '%s\n' "$dir"
}

commit_rejected() {
    dir="$1"
    description="$2"
    pattern="$3"

    if git -C "$dir" commit -q --allow-empty -m "test commit" >"$tmp/output" 2>&1; then
        fail "$description (commit was accepted)"
    fi
    if git -C "$dir" rev-parse --verify --quiet HEAD >/dev/null; then
        fail "$description (a commit was created despite rejection)"
    fi
    if [ -n "$pattern" ] && ! grep -q "$pattern" "$tmp/output"; then
        cat "$tmp/output" >&2
        fail "$description (missing expected error text: $pattern)"
    fi
}

commit_accepted() {
    dir="$1"
    description="$2"

    if ! git -C "$dir" commit -q --allow-empty -m "test commit" >"$tmp/output" 2>&1; then
        cat "$tmp/output" >&2
        fail "$description (commit was rejected)"
    fi
}

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com
repo=$(make_repo)
commit_accepted "$repo" "matching identity"
pass "matching identity is accepted"

clear_identity_env
export GIT_USER_NAME=Bob GIT_USER_EMAIL=alice@example.com
repo=$(make_repo)
commit_rejected "$repo" "mismatched name" 'GIT_USER_NAME'
pass "mismatched name is rejected"

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=bob@example.com
repo=$(make_repo)
commit_rejected "$repo" "mismatched email" 'GIT_USER_EMAIL'
pass "mismatched email is rejected"

clear_identity_env
repo=$(make_repo)
git -C "$repo" config user.name Bob
git -C "$repo" config user.email bob@example.com
commit_accepted "$repo" "unset variables"
pass "unset variables disable enforcement"

clear_identity_env
export GIT_USER_NAME=Alice
repo=$(make_repo)
git -C "$repo" config user.email bob@example.com
commit_accepted "$repo" "only name set"
pass "only name set: matching name with different email is accepted"

clear_identity_env
export GIT_USER_NAME=Bob
repo=$(make_repo)
commit_rejected "$repo" "only name set mismatch" 'GIT_USER_NAME'
pass "only name set: mismatched name is rejected"

clear_identity_env
export GIT_USER_EMAIL=alice@example.com
repo=$(make_repo)
git -C "$repo" config user.name Bob
commit_accepted "$repo" "only email set"
pass "only email set: matching email with different name is accepted"

clear_identity_env
export GIT_USER_EMAIL=bob@example.com
repo=$(make_repo)
commit_rejected "$repo" "only email set mismatch" 'GIT_USER_EMAIL'
pass "only email set: mismatched email is rejected"

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com GIT_AUTHOR_NAME=Bob
repo=$(make_repo)
commit_rejected "$repo" "author override" 'author name'
pass "GIT_AUTHOR_NAME override is rejected"

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com GIT_COMMITTER_EMAIL=bob@example.com
repo=$(make_repo)
commit_rejected "$repo" "committer override" 'committer email'
pass "GIT_COMMITTER_EMAIL override is rejected"

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com
repo=$(make_repo)
marker="$tmp/local-hook-ran"
cat >"$repo/.git/hooks/pre-commit" <<EOF
#!/bin/sh
: >"$marker"
EOF
chmod +x "$repo/.git/hooks/pre-commit"
commit_accepted "$repo" "local hook coexistence"
[ -f "$marker" ] || fail "local pre-commit hook did not run"
pass "local pre-commit hook still runs"

clear_identity_env
export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com
repo=$(make_repo)
if ! git -C "$repo" hook list pre-commit --show-scope | grep -q 'identity-test'; then
    git -C "$repo" hook list pre-commit --show-scope >&2
    fail "global hook is not listed by git hook list"
fi
pass "global hook is visible through git hook list"

clear_identity_env
config_home="$tmp/config-home"
mkdir -p "$config_home"
(
    unset GIT_CONFIG_GLOBAL OPENCODE_SSH_KEY
    export HOME="$config_home"
    export GIT_USER_NAME=Alice GIT_USER_EMAIL=alice@example.com

    . "$repo_root/git-config.sh"

    [ "$(git config --global --get user.name)" = "Alice" ] \
        || fail "git-config.sh did not set user.name"
    [ "$(git config --global --get user.email)" = "alice@example.com" ] \
        || fail "git-config.sh did not set user.email"
    [ "$(git config --global --get hook.verify-commit-identity.command)" = "/usr/local/bin/git-identity-hook" ] \
        || fail "git-config.sh did not configure the hook command"
    [ "$(git config --global --get hook.verify-commit-identity.event)" = "pre-commit" ] \
        || fail "git-config.sh did not configure the hook event"
    [ "${GIT_USER_NAME:-}" = "Alice" ] \
        || fail "git-config.sh unset GIT_USER_NAME"
    [ "${GIT_USER_EMAIL:-}" = "alice@example.com" ] \
        || fail "git-config.sh unset GIT_USER_EMAIL"
)
pass "git-config.sh installs the global hook and preserves the identity variables"

printf 'All tests passed.\n'
