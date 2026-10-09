# buzz — production context

Written by the Nexlayer agent so any coding agent that opens this repo
starts with the same picture. Read this before proposing infrastructure
changes.

- **Repo** `https://github.com/sasdeployer/buzz` on `main`
- **Analyzed** 2026-10-09T05:07:47.573Z

## Stack

| Component | Version | How we know |
| --- | --- | --- |
| Rust | 1.88 toolchain (Dockerfile builds with 1.95) | read from `Cargo.toml`, `rust-toolchain.toml`, `Dockerfile` |
| Axum | 0.8 | read from `Cargo.toml` |
| Tokio | 1 | read from `Cargo.toml` |
| PostgreSQL | 17 | read from `docker-compose.yml`, `.env.example` |
| Redis | 7 | read from `docker-compose.yml`, `.env.example` |
| Typesense | unpinned | read from `.env.example`, `docker-compose.yml` |
| Keycloak | 26.0 (quay.io/keycloak/keycloak) | read from `docker-compose.yml` |
| Adminer | latest | read from `docker-compose.yml` |
| pnpm workspace | 11.4.0 | read from `package.json`, `pnpm-workspace.yaml` |
| Vite | unpinned (buzz-web static bundle) | read from `Dockerfile` |
| SQLx | 0.9 | read from `Cargo.toml` |
| Git | system dependency of relay image | read from `Dockerfile` |
| Prometheus | unpinned | read from `prometheus.yml`, `root listing` |

## How Nexlayer will run it

| Service | Reachable | Image | How we know |
| --- | --- | --- | --- |
| `relay` | public | `registry.nexlayer.io/YOUR_USER_ID/buzz-relay:planned` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `postgres` | internal only | `mirror.gcr.io/library/postgres:17-alpine` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `redis` | internal only | `mirror.gcr.io/library/redis:7-alpine` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `typesense` | internal only | `mirror.gcr.io/typesense/typesense:28.0` | read from `.nexlayer/drafts/nexlayer.yaml` |
| `minio` | internal only | `mirror.gcr.io/minio/minio:latest` | read from `.nexlayer/drafts/nexlayer.yaml` |

Reachability is inferred from service names and roles, not stated by the
analysis. Check it before relying on it — exposing something that should
be internal is not recoverable by editing this file afterwards.

Networking, HTTPS, and service discovery are handled.

## Secrets

This app uses 5 keys: 2 required to run, 3 optional.

Keys reach the app by name. In `nexlayer.yaml`, write `${NAME}` where the
value goes (e.g. `OPENAI_API_KEY: "${OPENAI_API_KEY}"`) — never the value.
When you deploy through the Nexlayer MCP, Nexlayer fills each name from this
app's Secrets. Values never go in this repo, the chat, or your context.

- `TYPESENSE_API_KEY` — **still needed from the human**
- `KEYCLOAK_ADMIN_PASSWORD` — **still needed from the human**
- `BUZZ_S3_ACCESS_KEY` — optional, not set. Found in the code; not needed to start the app.
- `BUZZ_S3_SECRET_KEY` — optional, not set. Found in the code; not needed to start the app.
- `PGPASSWORD` — optional, not set. Found in the code; not needed to start the app.

If you are a coding agent: do not ask the human to paste a missing key into
the chat, and do not write one into this repo.

## Notes from the analysis

- One service per pod: relay, postgres, redis, typesense, keycloak, adminer, and the push gateway each run in their own pod.
- Inter-pod communication uses <podName>.pod:<port>: the relay reaches Postgres at postgres.pod:5432, Redis at redis.pod:6379, and Typesense at typesense.pod:8108 — never localhost or bare hostnames.
- Postgres is a separate pod from the relay (Rule 4) and persists via PGDATA volume; run migrations (migrations/ dir) against postgres.pod:5432 before/onsstartup.
- Postgres, Redis, and Adminer images were rewritten from Docker Hub to mirror.gcr.io/library/*; Keycloak stays on quay.io (not Docker Hub); Typesense is mirrored via mirror.gcr.io/typesense/typesense.
- Keycloak runs in start-dev / dev-mem mode per docker-compose.yml; production should switch KC_DB to the postgres pod and set real admin credentials.
- The relay image (ghcr.io/block/buzz) bundles the buzz-relay Rust binary plus the static buzz-web frontend and requires git in the runtime image for repository operations.

## Talking to Nexlayer

Nexlayer is reachable over MCP. Call `nexlayer_get_deployment_workflow`
before deploying — it is the current procedure, and it changes more often
than this file does.
