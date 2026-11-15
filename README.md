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
| `OPENCODE_MODEL` | The repository's selected model, or the catalog default. |

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
| `GIT_USER_NAME` | Git name is set | Commit identity configured at startup. |
| `GIT_USER_EMAIL` | Git email is set | Commit identity configured at startup. |
| `OPENCODE_INSTRUCTION` | Instruction is set | Legacy: previously written to `AGENTS.md` at startup. Ignored by this image because `AGENTS.md` is baked in at build time. |

### Added for command execution only

| Variable | Purpose |
| --- | --- |
| `OPENCODE_RUN_ID` | Marks the process tree so `/cancel` can terminate it. |
| `OPENCODE_CANCEL_TOKEN` | Set on the cancel helper process as `OPENCODE_RUN_ID=<runID>`. |

Bot-only variables such as `TELEGRAM_*`, `ALLOWED_USER_ID`, `OPENCODE_MODELS`,
`HOST_REPOS_DIR`, and `DATA_DIR` are not forwarded to workers.

The container starts at `/workspace`, configures Git, and then idles until used.
