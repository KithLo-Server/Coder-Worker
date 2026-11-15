# Coder-Worker

Container image for the OpenCode worker used by the Coder bot.

The image extends `ghcr.io/kithlo-server/worker:latest` (Ubuntu 26.04 with the
Android SDK/NDK, Rust, Java, Go, and Node.js), installs the OpenCode CLI, and
provides the entrypoint used by per-repository worker containers.

## Build

```sh
docker build -t ghcr.io/kithlo-server/coder-worker:latest .
```

The `.github/workflows/build-worker.yml` workflow builds and pushes
`ghcr.io/kithlo-server/coder-worker:latest` on every push to `master` and via
manual dispatch. It runs on an arm64 runner because the base image is
`linux/arm64` only.

## Runtime environment

| Variable | Purpose |
| --- | --- |
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | Service-account JSON written to `/root/.gcp-credentials.json` at startup. |
| `OPENCODE_INSTRUCTION` | Free-form instructions written to `/root/.config/opencode/AGENTS.md` at startup. |
| `OPENCODE_SSH_KEY` | SSH private key used for Git authentication and commit signing. |
| `GIT_USER_NAME` / `GIT_USER_EMAIL` | Commit identity configured at startup. |

The container starts at `/workspace`, configures Git, and then idles until used.
