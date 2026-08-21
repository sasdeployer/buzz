# Nexlayer — buzz

<!-- nexlayer:meta version=1 analyzed=2026-08-21T04:44:38Z repo=https://github.com/sasdeployer/buzz branch=nexlayer -->

> **For AI agents (Claude Code, Cursor, Gemini CLI, Copilot):**
> This file is the **project context** for this Nexlayer deployment — tech stack, env vars, secrets, live URL.
> For full platform detail (nexlayer.yaml schema, Dockerfile rules, CI/CD, task recipes) read **`nexlayer.skills`** in this repo.
>
> **Critical rules (full detail in `nexlayer.skills`):**
> - Inter-pod refs: `${podName:port}` only — never `localhost` or bare hostnames
> - Docker Hub images: prefix with `mirror.gcr.io/library/` — bare tags fail on the cluster
> - Secrets: set in the Nexlayer dashboard — never commit to `nexlayer.yaml` or Dockerfile
>
> **This file:** `agent-managed` sections update automatically. `user-editable` sections (Local Development Setup, Nexlayer Deployment Plan, Build Notes) are yours — preserved across re-analysis.

## Project Summary
<!-- nexlayer:section agent-managed=project_summary -->
Buzz is a self-hostable Nostr-based workspace where humans and AI agents collaborate in shared rooms, with features like channels, workflows, git integration, and voice huddles. It includes a Rust relay backend, web frontends, and supporting services like Postgres, Redis, and Typesense.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| Rust | language | 1.95 | Cargo.toml, Dockerfile |
| TypeScript | language | 5.x | package.json, pnpm-workspace.yaml |
| Axum | framework | 0.8 | Cargo.toml |
| Vite | framework | 5.x | web/package.json |
| React | framework | 18.x | web/package.json |
| PostgreSQL | database | 17 | .env.example, docker-compose.yml |
| Redis | database | 7 | .env.example, docker-compose.yml |
| Typesense | database | latest | .env.example |
| Keycloak | infra | 26.0 | docker-compose.yml |
| Docker | build | latest | Dockerfile, docker-compose.yml |
| pnpm | build | 11.4.0 | package.json |
| Cargo | build | 1.95 | Cargo.toml |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- crates/buzz-relay — main WebSocket relay server
- crates/buzz-core — core domain logic
- crates/buzz-push-gateway — push notification gateway
- crates/buzz-db — database access layer
- crates/buzz-pubsub — pub/sub abstractions
- crates/buzz-auth — authentication
- crates/buzz-search — search integration
- crates/buzz-audit — audit logging
- crates/buzz-acp — agent communication protocol
- crates/buzz-agent — agent orchestration
- crates/sprig — sprig tool
- crates/buzz-admin — admin API
- crates/buzz-workflow — workflow engine
- crates/buzz-media — media handling
- crates/buzz-voice — voice huddles
- crates/buzz-relay-mesh — relay mesh networking
- crates/buzz-backend-kubernetes — Kubernetes backend provider
- web — web frontend (Vite/React)
- admin-web — admin frontend
- desktop — desktop app (Tauri)
- migrations — database migrations
- deploy — deployment manifests
- nexlayer.yaml — Nexlayer configuration
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- Nostr protocol (relay events)
- Git (shelled out for repo operations)
- S3-compatible storage (MinIO) for media
- Keycloak for identity (optional)
- Typesense for search
<!-- nexlayer:end -->

## Local Development Setup
<!-- nexlayer:section user-editable=local_setup -->
### Prerequisites

- Rust 1.95
- Node.js >= 24
- pnpm >= 11.4.0
- Docker
- Docker Compose

### Environment variables

Copy `.env.example` to `.env.local` and fill in:

```
DATABASE_URL=postgres://buzz:buzz_dev@localhost:5432/buzz
REDIS_URL=redis://localhost:6379
TYPESENSE_API_KEY=buzz_dev_key
TYPESENSE_URL=http://localhost:8108
RELAY_URL=ws://localhost:3000
BUZZ_BIND_ADDR=0.0.0.0:3000
BUZZ_S3_ENDPOINT=http://localhost:9000
BUZZ_S3_ACCESS_KEY=buzz_dev
BUZZ_S3_SECRET_KEY=buzz_dev_secret
BUZZ_S3_BUCKET=buzz-media
BUZZ_S3_REGION=us-east-1
BUZZ_S3_ADDRESSING_STYLE=path
```

### Steps

1. `cp .env.example .env` — Create local environment file
2. `docker compose up -d` — Start Postgres, Redis, Typesense, Adminer, Keycloak, and MinIO (if configured)
3. `pnpm install` — Install web dependencies
4. `cargo build` — Build Rust relay binary
5. `cargo run -p buzz-relay` — Start the relay server on http://localhost:3000
6. `pnpm --filter web dev` — Start web frontend dev server

<!-- nexlayer:end -->

## Nexlayer Setup
<!-- nexlayer:section agent-managed=nexlayer_setup -->
### Pod Environment Variables

| Pod | Variable | Value | Kind |
|-----|----------|-------|------|
| `relay` | `BUZZ_BIND_ADDR` | `"0.0.0.0:3000"` | plain |
| `relay` | `RELAY_URL` | `"ws://relay.pod:3000"` | plain |
| `relay` | `DATABASE_URL` | `"postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"` | inter-pod |
| `relay` | `REDIS_URL` | `"redis://redis.pod:6379"` | plain |
| `relay` | `TYPESENSE_URL` | `"http://search.pod:8108"` | plain |
| `relay` | `TYPESENSE_API_KEY` | `"${TYPESENSE_API_KEY}"` | inter-pod |
| `relay` | `BUZZ_S3_ENDPOINT` | `"http://minio.pod:9000"` | plain |
| `relay` | `BUZZ_S3_ACCESS_KEY` | `"${BUZZ_S3_ACCESS_KEY}"` | inter-pod |
| `relay` | `BUZZ_S3_SECRET_KEY` | `"${BUZZ_S3_SECRET_KEY}"` | inter-pod |
| `relay` | `BUZZ_S3_BUCKET` | `"buzz-media"` | plain |
| `relay` | `BUZZ_S3_REGION` | `"us-east-1"` | plain |
| `relay` | `BUZZ_WEB_DIR` | `"/web/dist"` | plain |
| `relay` | `RUST_LOG` | `"buzz_relay=debug,buzz_datastore=info,buzz_db=debug,buzz_auth=debug,buzz_pubsub=debug,tower_http=debug"` | plain |
| `postgres` | `POSTGRES_USER` | `"app"` | plain |
| `postgres` | `POSTGRES_PASSWORD` | `"${POSTGRES_PASSWORD}"` | inter-pod |
| `postgres` | `POSTGRES_DB` | `"app"` | plain |
| `buzz-postgres-data` | `size` | `10Gi` | plain |
| `buzz-postgres-data` | `mountPath` | `/var/lib/postgresql` | plain |
| `search` | `TYPESENSE_API_KEY` | `"${TYPESENSE_API_KEY}"` | inter-pod |
| `search` | `TYPESENSE_DATA_DIR` | `/data` | plain |
| `buzz-typesense-data` | `size` | `5Gi` | plain |
| `buzz-typesense-data` | `mountPath` | `/data` | plain |
| `minio` | `command` | `"server /data --console-address \":9001\""` | plain |
| `minio` | `MINIO_ROOT_USER` | `"${MINIO_ROOT_USER}"` | inter-pod |
| `minio` | `MINIO_ROOT_PASSWORD` | `"${MINIO_ROOT_PASSWORD}"` | inter-pod |
| `buzz-minio-data` | `size` | `10Gi` | plain |
| `buzz-minio-data` | `mountPath` | `/data` | plain |
| `keycloak` | `command` | `"start-dev --http-port=8080"` | plain |
| `keycloak` | `KC_DB` | `dev-mem` | plain |
| `keycloak` | `KEYCLOAK_ADMIN` | `admin` | plain |
| `keycloak` | `KEYCLOAK_ADMIN_PASSWORD` | `"${KEYCLOAK_ADMIN_PASSWORD}"` | inter-pod |
| `push-gateway` | `DATABASE_URL` | `"postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"` | inter-pod |
| `push-gateway` | `REDIS_URL` | `"redis://redis.pod:6379"` | plain |
| `push-gateway` | `RELAY_URL` | `"ws://relay.pod:3000"` | plain |
| `admin` | `NODE_ENV` | `production` | plain |
| `agent` | `DATABASE_URL` | `"postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"` | inter-pod |
| `agent` | `REDIS_URL` | `"redis://redis.pod:6379"` | plain |
| `agent` | `RELAY_URL` | `"ws://relay.pod:3000"` | plain |
| `workflow` | `DATABASE_URL` | `"postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"` | inter-pod |
| `workflow` | `REDIS_URL` | `"redis://redis.pod:6379"` | plain |
| `workflow` | `RELAY_URL` | `"ws://relay.pod:3000"` | plain |
| `media` | `DATABASE_URL` | `"postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"` | inter-pod |
| `media` | `REDIS_URL` | `"redis://redis.pod:6379"` | plain |
| `media` | `BUZZ_S3_ENDPOINT` | `"http://minio.pod:9000"` | plain |
| `media` | `BUZZ_S3_ACCESS_KEY` | `"${BUZZ_S3_ACCESS_KEY}"` | inter-pod |
| `media` | `BUZZ_S3_SECRET_KEY` | `"${BUZZ_S3_SECRET_KEY}"` | inter-pod |
| `media` | `BUZZ_S3_BUCKET` | `"buzz-media"` | plain |
| `media` | `BUZZ_S3_REGION` | `"us-east-1"` | plain |

### nexlayer.yaml

```yaml
application:
  name: buzz
  pods:
    - name: relay
      image: "registry.nexlayer.io/user_01kdnssb5ktgqr1mawtnz48s00/buzz:a0229e7-fix6"
      path: /
      servicePorts:
        - 3000
      vars:
        BUZZ_BIND_ADDR: "0.0.0.0:3000"
        RELAY_URL: "ws://relay.pod:3000"
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        TYPESENSE_URL: "http://search.pod:8108"
        TYPESENSE_API_KEY: "${TYPESENSE_API_KEY}"
        BUZZ_S3_ENDPOINT: "http://minio.pod:9000"
        BUZZ_S3_ACCESS_KEY: "${BUZZ_S3_ACCESS_KEY}"
        BUZZ_S3_SECRET_KEY: "${BUZZ_S3_SECRET_KEY}"
        BUZZ_S3_BUCKET: "buzz-media"
        BUZZ_S3_REGION: "us-east-1"
        BUZZ_WEB_DIR: "/web/dist"
        RUST_LOG: "buzz_relay=debug,buzz_datastore=info,buzz_db=debug,buzz_auth=debug,buzz_pubsub=debug,tower_http=debug"
    - name: postgres
      image: mirror.gcr.io/library/postgres:17-alpine
      servicePorts:
        - 5432
      vars:
        POSTGRES_USER: "app"
        POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
        POSTGRES_DB: "app"
      volumes:
        - name: buzz-postgres-data
          size: 10Gi
          mountPath: /var/lib/postgresql
    - name: redis
      image: mirror.gcr.io/library/redis:7-alpine
      servicePorts:
        - 6379
      vars: {}
    - name: search
      image: mirror.gcr.io/library/typesense:latest
      servicePorts:
        - 8108
      vars:
        TYPESENSE_API_KEY: "${TYPESENSE_API_KEY}"
        TYPESENSE_DATA_DIR: /data
      volumes:
        - name: buzz-typesense-data
          size: 5Gi
          mountPath: /data
    - name: minio
      image: mirror.gcr.io/library/minio:latest
      command: "server /data --console-address \":9001\""
      servicePorts:
        - 9000
      vars:
        MINIO_ROOT_USER: "${MINIO_ROOT_USER}"
        MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
      volumes:
        - name: buzz-minio-data
          size: 10Gi
          mountPath: /data
    - name: keycloak
      image: quay.io/keycloak/keycloak:26.0
      command: "start-dev --http-port=8080"
      servicePorts:
        - 8080
      vars:
        KC_DB: dev-mem
        KEYCLOAK_ADMIN: admin
        KEYCLOAK_ADMIN_PASSWORD: "${KEYCLOAK_ADMIN_PASSWORD}"
    - name: push-gateway
      image: ghcr.io/block/buzz-push-gateway:latest
      servicePorts:
        - 8080
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: admin
      image: ghcr.io/block/buzz-admin:latest
      path: /admin
      servicePorts:
        - 8081
      vars:
        NODE_ENV: production
    - name: agent
      image: ghcr.io/block/buzz-agent:latest
      servicePorts:
        - 8082
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: workflow
      image: ghcr.io/block/buzz-workflow:latest
      servicePorts:
        - 8083
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: media
      image: ghcr.io/block/buzz-media:latest
      servicePorts:
        - 8084
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        BUZZ_S3_ENDPOINT: "http://minio.pod:9000"
        BUZZ_S3_ACCESS_KEY: "${BUZZ_S3_ACCESS_KEY}"
        BUZZ_S3_SECRET_KEY: "${BUZZ_S3_SECRET_KEY}"
        BUZZ_S3_BUCKET: "buzz-media"
        BUZZ_S3_REGION: "us-east-1"
```

<!-- nexlayer:end -->

## Nexlayer Deployment Plan
<!-- nexlayer:section user-editable=deployment_plan -->
### Pod Topology

| Pod | Image | Port | Role |
|-----|-------|------|------|
| relay | ghcr.io/block/buzz:latest | 3000 | web |
| db | mirror.gcr.io/library/postgres:17-alpine | 5432 | database |
| redis | mirror.gcr.io/library/redis:7-alpine | 6379 | cache |
| typesense | mirror.gcr.io/library/typesense:latest | 8108 | database |
| push-gateway | ghcr.io/block/buzz-push-gateway:latest | 8080 | worker |
| sprig | ghcr.io/block/buzz-sprig:latest | 8081 | worker |

### Deployment notes

- All inter-pod communication uses <podName>.pod:<port> form, e.g., relay connects to db.pod:5432, redis.pod:6379, typesense.pod:8108.
- Each service runs in its own pod; no co-location of daemons.
- Docker Hub images are prefixed with mirror.gcr.io/library/ to comply with cluster image policy.
- The relay image is built from the provided Dockerfile and published to ghcr.io/block/buzz.
- Push gateway and sprig are separate binaries built from the workspace and run as separate pods.
- Database migrations should be run as a one-off job before starting the relay.
- Persistent volumes are required for Postgres (PGDATA) and Typesense data.
- Keycloak is optional and can be deployed as a separate pod if needed for identity.
- MinIO (S3) is required for media storage; deploy as a separate pod if not using an external S3 service.

<!-- nexlayer:end -->

## Build Notes
<!-- nexlayer:section user-editable=build_notes -->
<!-- Add notes for future builds here — preserved across re-analysis -->
<!-- nexlayer:end -->

## Nexlayer Configuration
<!-- nexlayer:section agent-managed=nexlayer_config -->
**Last deployed:** 2026-08-21T06:25:36Z  
**Live URL:** https://zen-antelope-buzz.cloud.nexlayer.ai  
**Runtime:**  · **Port:** auto-detected  
**Deploy branch:** nexlayer  

```yaml
application:
  name: buzz
  pods:
    - name: relay
      image: "registry.nexlayer.io/user_01kdnssb5ktgqr1mawtnz48s00/buzz:a0229e7-fix6"
      path: /
      servicePorts:
        - 3000
      vars:
        BUZZ_BIND_ADDR: "0.0.0.0:3000"
        RELAY_URL: "ws://relay.pod:3000"
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        TYPESENSE_URL: "http://search.pod:8108"
        TYPESENSE_API_KEY: "${TYPESENSE_API_KEY}"
        BUZZ_S3_ENDPOINT: "http://minio.pod:9000"
        BUZZ_S3_ACCESS_KEY: "${BUZZ_S3_ACCESS_KEY}"
        BUZZ_S3_SECRET_KEY: "${BUZZ_S3_SECRET_KEY}"
        BUZZ_S3_BUCKET: "buzz-media"
        BUZZ_S3_REGION: "us-east-1"
        BUZZ_WEB_DIR: "/web/dist"
        RUST_LOG: "buzz_relay=debug,buzz_datastore=info,buzz_db=debug,buzz_auth=debug,buzz_pubsub=debug,tower_http=debug"
    - name: postgres
      image: mirror.gcr.io/library/postgres:17-alpine
      servicePorts:
        - 5432
      vars:
        POSTGRES_USER: "app"
        POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
        POSTGRES_DB: "app"
      volumes:
        - name: buzz-postgres-data
          size: 10Gi
          mountPath: /var/lib/postgresql
    - name: redis
      image: mirror.gcr.io/library/redis:7-alpine
      servicePorts:
        - 6379
      vars: {}
    - name: search
      image: mirror.gcr.io/library/typesense:latest
      servicePorts:
        - 8108
      vars:
        TYPESENSE_API_KEY: "${TYPESENSE_API_KEY}"
        TYPESENSE_DATA_DIR: /data
      volumes:
        - name: buzz-typesense-data
          size: 5Gi
          mountPath: /data
    - name: minio
      image: mirror.gcr.io/library/minio:latest
      command: "server /data --console-address \":9001\""
      servicePorts:
        - 9000
      vars:
        MINIO_ROOT_USER: "${MINIO_ROOT_USER}"
        MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD}"
      volumes:
        - name: buzz-minio-data
          size: 10Gi
          mountPath: /data
    - name: keycloak
      image: quay.io/keycloak/keycloak:26.0
      command: "start-dev --http-port=8080"
      servicePorts:
        - 8080
      vars:
        KC_DB: dev-mem
        KEYCLOAK_ADMIN: admin
        KEYCLOAK_ADMIN_PASSWORD: "${KEYCLOAK_ADMIN_PASSWORD}"
    - name: push-gateway
      image: ghcr.io/block/buzz-push-gateway:latest
      servicePorts:
        - 8080
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: admin
      image: ghcr.io/block/buzz-admin:latest
      path: /admin
      servicePorts:
        - 8081
      vars:
        NODE_ENV: production
    - name: agent
      image: ghcr.io/block/buzz-agent:latest
      servicePorts:
        - 8082
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: workflow
      image: ghcr.io/block/buzz-workflow:latest
      servicePorts:
        - 8083
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        RELAY_URL: "ws://relay.pod:3000"
    - name: media
      image: ghcr.io/block/buzz-media:latest
      servicePorts:
        - 8084
      vars:
        DATABASE_URL: "postgresql://app:${POSTGRES_PASSWORD}@postgres.pod:5432/app"
        REDIS_URL: "redis://redis.pod:6379"
        BUZZ_S3_ENDPOINT: "http://minio.pod:9000"
        BUZZ_S3_ACCESS_KEY: "${BUZZ_S3_ACCESS_KEY}"
        BUZZ_S3_SECRET_KEY: "${BUZZ_S3_SECRET_KEY}"
        BUZZ_S3_BUCKET: "buzz-media"
        BUZZ_S3_REGION: "us-east-1"
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-08-21T04:44:38Z | analyzed | initial repo analysis |
| 2026-08-21T06:25:36Z | success | deployed https://zen-antelope-buzz.cloud.nexlayer.ai |
<!-- nexlayer:end -->
