# Nexlayer — how `buzz` ships

You were asked to work on or deploy this app. The state below is already
resolved — do not re-derive it from the code. The procedure is not here;
ask Nexlayer for it (see "How to deploy").

## The app

| | |
| --- | --- |
| Name | `buzz` |
| Repo | `https://github.com/sasdeployer/buzz` on `main` |
| Planned | 2026-10-09T05:08:45.258Z |
| Registered with Nexlayer | yes |

`.nexlayer/plan.lock` pins the commit this plan was written against. If HEAD
has moved and you changed how the app starts, runs, or what it needs,
re-check before deploying.

## The production plan

Written by the Nexlayer agent from this repo. Every decision cites the files it
rests on; if the code has changed since, re-check those files first.

Buzz is a Rust Axum Nostr relay that serves a Vite web bundle and connects to Postgres 17, Redis 7, Typesense search, and S3-compatible media storage (MinIO). On Nexlayer it runs as five pods: the relay (built from the repo Dockerfile) fronting traffic, with Postgres, Redis, Typesense, and MinIO as companion services, each on its own persistent volume. The thing that matters most is keeping the relay's Postgres, Redis, S3, and Typesense credentials and addresses consistent across pods so the relay can migrate, store, and search on first boot.

- **services: Convert docker-compose.yml / deploy/compose/compose.yml into five pods: relay, postgres, redis, typesense, and minio; drop Adminer, Prometheus, Keycloak, and Caddy.** — Adminer, Prometheus, and the Caddy reverse proxy are dev/ops tooling Nexlayer replaces or that isn't part of the app, and Keycloak runs only in start-dev/dev-mem mode with admin/admin credentials, which is not production-usable; the relay's own auth is Nostr-based (buzz-auth NIP-42/98). (`docker-compose.yml`, `deploy/compose/compose.yml`, `deploy/compose/compose.dev.yml`, `deploy/compose/compose.caddy.yml`, `crates/buzz-auth/Cargo.toml`)
- **database: Postgres 17 in its own pod (mirror.gcr.io/library/postgres:17-alpine) with a volume, matching the version pinned in compose.** — The compose files pin postgres:17-alpine and the relay stores all events there, so the data must survive restarts. (`docker-compose.yml`, `deploy/compose/compose.yml`, `crates/buzz-db/Cargo.toml`)
- **database: Run SQLx migrations in the relay's startup via BUZZ_AUTO_MIGRATE=true rather than a one-shot migration pod.** — deploy/compose/compose.yml already exposes BUZZ_AUTO_MIGRATE for exactly this, and the platform rejects pods that exit. (`deploy/compose/compose.yml`, `migrations`)
- **storage: Keep MinIO as the media backend (mirror.gcr.io/minio/minio) with a volume, wired to the relay via path-style S3 env vars; its root credentials use the same keys the relay reads.** — deploy/compose/compose.yml sets BUZZ_S3_ENDPOINT/BUZZ_S3_BUCKET/BUZZ_S3_ACCESS_KEY/BUZZ_S3_SECRET_KEY and mounts nothing persistent in the relay for media, so object storage holds the uploads. (`deploy/compose/compose.yml`, `deploy/compose/.env.example`, `crates/buzz-media/Cargo.toml`)
- **storage: Give the relay a persistent volume at /data/git for BUZZ_GIT_REPO_PATH.** — The relay shells out to git for repo hydrate/receive-pack/upload-pack and stores repo data on disk at /data/git in the production compose. (`deploy/compose/compose.yml`, `Dockerfile`, `crates/buzz-relay/src/api/git`)
- **database: Run Typesense in its own pod with a volume, referenced by the relay at http://typesense.pod:8108.** — The relay depends on Typesense for search (.env.example TYPESENSE_URL/TYPESENSE_API_KEY) and Typesense keeps its index on local disk. (`.env.example`, `docker-compose.yml`, `crates/buzz-search/Cargo.toml`)
- **keys: Reference all secrets by name only: ${POSTGRES_PASSWORD}, ${REDIS_PASSWORD}, ${TYPESENSE_API_KEY}, ${BUZZ_S3_ACCESS_KEY}, ${BUZZ_S3_SECRET_KEY}, ${RELAY_OWNER_PUBKEY}, ${BUZZ_RELAY_PRIVATE_KEY}, ${BUZZ_GIT_HOOK_HMAC_SECRET}, ${BUZZ_REQUIRE_AUTH_TOKEN}; MinIO's root user/password use the same ${BUZZ_S3_*} names so the relay and storage agree.** — deploy/compose/.env.example marks these as CHANGE_ME stable secrets the operator must provision, and connection strings must never contain literals. (`deploy/compose/.env.example`, `deploy/compose/compose.yml`)
- **health: Expose the relay on port 3000 (BUZZ_BIND_ADDR 0.0.0.0:3000) with its health (8080) and metrics (9102) ports also declared.** — deploy/compose/compose.yml sets those exact ports and healthchecks /_readiness on 8080. (`deploy/compose/compose.yml`, `crates/buzz-relay/src/metrics.rs`)

### Fix before production

- Handle MinIO bucket creation without the one-shot minio-init container: deploy/compose/compose.yml depends on a run-to-completion minio-init (mc) service that creates the buzz-media bucket; the platform rejects one-shot pods, and without the bucket media uploads fail. (`deploy/compose/compose.yml`)
- Provision RELAY_OWNER_PUBKEY and BUZZ_RELAY_PRIVATE_KEY before first deploy: deploy/compose/.env.example marks the owner pubkey and stable relay private key as required for closed-relay mode; deploying without them leaves auth/membership enforcement unconfigured. (`deploy/compose/.env.example`)

### Verify after the deploy

1. GET / on the app URL returns 200 and serves the buzz-web bundle
2. GET /_readiness via the relay health port (8080) through internal networking returns 200 after migrations complete
3. A WebSocket connection to the app URL (wss) completes the Nostr handshake (REQ/EVENT round-trip)
4. Upload a file through the relay media API and confirm the object appears in MinIO (bucket buzz-media)
5. Confirm Typesense answers search queries from the relay (channel/message search returns results after events are written)

### Ask the human

- Is Keycloak actually required for any production auth flow, or is Nostr-based auth (NIP-42/98) sufficient? The compose only runs it in dev-mem mode.
- Should media move from the bundled MinIO to an external S3 provider at scale?

## Drafts in this plan

This repo had no deploy config, so this plan adds drafts where files were
missing (never over an existing file):

- `nexlayer.yaml` — what runs, written by the Nexlayer agent (see "The production plan"). It passes the Nexlayer validator.

Build them once, fix what fails, then deploy with `.nexlayer/pipeline.yaml`.
After the first successful deploy, these files are the source of truth.

## Can this deploy right now?

**Not yet — 2 missing keys (the human's).** Full list in `.nexlayer/todo.md`.

## How to deploy

Call `nexlayer_get_deployment_workflow` first. It returns the current
procedure — building and pushing the image included — and it is kept up to
date in a way this file is not. Do not infer the steps from here, and do
not skip it because the app looks simple.

If Nexlayer tools are not available to you, the human runs
`npx @nexlayer/mcp-install` once.

## Secrets

Keys reach the app by name. In `nexlayer.yaml`, write `${NAME}` where the
value goes (e.g. `OPENAI_API_KEY: "${OPENAI_API_KEY}"`) — never the value.
When you deploy through the Nexlayer MCP, Nexlayer fills each name from this
app's Secrets. Values never go in this repo, the chat, or your context.

| Key | Status |
| --- | --- |
| `TYPESENSE_API_KEY` | **missing** |
| `KEYCLOAK_ADMIN_PASSWORD` | **missing** |
| `BUZZ_S3_ACCESS_KEY` | not set — optional, the app runs without it |
| `BUZZ_S3_SECRET_KEY` | not set — optional, the app runs without it |
| `PGPASSWORD` | not set — optional, the app runs without it |

Keys marked supplied are handled. Do not ask for them again.

For a missing key: **do not ask the human to paste it into the chat, and do**
**not write it into this repo.** Both put a live credential somewhere it
cannot be taken back from. Send them to the app's Secrets instead, wait
until they say it is added, then deploy:

<http://localhost:3001/apps/86fa4f48-3d73-45f2-9629-94b7c3c55fde/keys>

Optional keys: leave them out of `nexlayer.yaml` unless the human wants that
feature on — then they add the key in the same Secrets page and you add its
`${NAME}` reference.

## What was inferred rather than read

Nothing. Every claim in this plan was read from the repo.

## What "it worked" means

After every deploy, run `nexlayer_verify_deploy`. A deploy is accepted before it is
known to work; only "✓ Working" means it worked. It runs the `verify` list in
`.nexlayer/pipeline.yaml`, and when the app is broken it says what broke and why.

## Stop and ask the human

- A required key is missing (send the link above — never take the value).
- Something would become publicly reachable that is internal in this plan.
- Anything that deletes data or tears down a running deployment.

Everything else is yours to do. When something breaks, start at
`.nexlayer/TROUBLESHOOTING.md`.
