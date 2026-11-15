# Coder-Worker

Container image for the OpenCode worker used by the Coder bot.

The image extends `ghcr.io/kithlo-server/worker:latest` (Ubuntu 26.04 with the
Android SDK/NDK, Rust, Java, Go, and Node.js), installs the OpenCode CLI, and
provides the entrypoint used by per-repository worker containers.

The repository's `AGENTS.md` is baked into the image at
`/root/.config/opencode/AGENTS.md` at build time.

## Build

```sh
docker build -t ghcr.io/kithlo-server/coder-worker:latest .
```

The `.github/workflows/build-worker.yml` workflow builds and pushes
`ghcr.io/kithlo-server/coder-worker:latest` on every push to `master` and via
manual dispatch. It runs on an arm64 runner because the base image is
`linux/arm64` only.

## Runtime environment

The Coder bot injects these variables when it creates a worker container.

### Always injected

| Variable | Purpose |
| --- | --- |
| `DEEPSEEK_API_KEY` | DeepSeek provider API key. Included even when empty. |

### Injected when configured

| Variable | Condition | Purpose |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | `OPENROUTER_API_KEY` is set | OpenRouter provider authentication. |
| `GOOGLE_VERTEX_PROJECT` | Vertex project is set | Google Vertex AI project. |
| `GOOGLE_CLOUD_PROJECT` | Vertex project is set | Alias for the Vertex project. |
| `GOOGLE_VERTEX_LOCATION` | Vertex project is set | Vertex location, defaulting to `global`. |
| `GOOGLE_CLOUD_LOCATION` | Vertex project is set | Alias for the Vertex location. |
| `VERTEX_LOCATION` | Vertex project is set | Alias for the Vertex location. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Credentials JSON is set | Set to `/root/.gcp-credentials.json`. |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Credentials JSON is set | Service-account JSON written to `/root/.gcp-credentials.json` at startup. |
| `OPENCODE_SSH_KEY` | SSH key is set | SSH private key used for Git authentication and commit signing. |
| `GIT_USER_NAME` | Git name is set | Commit identity configured and enforced at startup. |
| `GIT_USER_EMAIL` | Git email is set | Commit identity configured and enforced at startup. |
| `OPENCODE_INSTRUCTION` | Instruction is set | Legacy: previously written to `AGENTS.md` at startup. Ignored by this image because `AGENTS.md` is baked in at build time. |

### Commit identity guard

Native config-based hooks require Git 2.54 or newer, so the image installs Git
2.56.1 from the `git-core` PPA.

When `GIT_USER_NAME` and/or `GIT_USER_EMAIL` are set, the image installs a
global native Git hook (`hook.verify-commit-identity`) for the `pre-commit`
event. It rejects commits whose effective author or committer name/email does
not match the set values. Each variable is enforced independently, so an unset
variable is not checked. Repository-local hooks still run alongside the global
hook, and `core.hooksPath` is not modified.

The guard does not apply to `git commit --no-verify`, to `--author` overrides,
or to commits created by commands that do not run the `pre-commit` hook (for
example `cherry-pick`, `rebase`, and `commit-tree`).

### Added for command execution only

| Variable | Purpose |
| --- | --- |
| `OPENCODE_RUN_ID` | Marks the process tree so `/cancel` can terminate it. |
| `OPENCODE_CANCEL_TOKEN` | Set on the cancel helper process as `OPENCODE_RUN_ID=<runID>`. |

Bot-only variables such as `TELEGRAM_*`, `ALLOWED_USER_ID`, `OPENCODE_MODELS`,
`HOST_REPOS_DIR`, and `DATA_DIR` are not forwarded to workers.

The container starts at `/workspace`, configures Git, and then idles until used.
