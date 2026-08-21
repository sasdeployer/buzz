# syntax=docker/dockerfile:1.7
#
# Public Buzz relay image — built from the repository's committed Dockerfile.
# Builds the buzz-relay binary (Rust 1.95) and the buzz-web static bundle (pnpm + vite),
# then assembles them into a small debian-slim runtime with git available.

ARG RUST_VERSION=1.95
ARG NODE_VERSION=24
ARG DEBIAN_VERSION=bookworm

# ─── Stage 1: cargo-chef base ───────────────────────────────────────────────
FROM mirror.gcr.io/library/rust:${RUST_VERSION}-${DEBIAN_VERSION} AS chef
ENV BUZZ_BIND_ADDR=0.0.0.0:3000
ENV BUZZ_S3_ACCESS_KEY=buzz_dev
ENV BUZZ_S3_ADDRESSING_STYLE=path
ENV BUZZ_S3_BUCKET=buzz-media
ENV BUZZ_S3_ENDPOINT=http://localhost:9000
ENV BUZZ_S3_REGION=us-east-1
ENV BUZZ_S3_SECRET_KEY=buzz_dev_secret
ENV DATABASE_URL=postgres://buzz:buzz_dev@localhost:5432/buzz
ENV PGDATABASE=buzz
ENV PGHOST=localhost
ENV PGPASSWORD=buzz_dev
ENV PGPORT=5432
ENV PGUSER=buzz
ENV REDIS_URL=redis://localhost:6379
ENV RELAY_URL=ws://localhost:3000
ENV RUST_LOG=buzz_relay=debug,buzz_datastore=info,buzz_db=debug,buzz_auth=debug,buzz_pubsub=debug,tower_http=debug
ENV TYPESENSE_API_KEY=buzz_dev_key
ENV TYPESENSE_URL=http://localhost:8108
RUN cargo install cargo-chef --locked --version 0.1.71
WORKDIR /build

# ─── Stage 2: planner ───────────────────────────────────────────────────────
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# ─── Stage 3: Rust builder ──────────────────────────────────────────────────
FROM chef AS builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        libssl-dev \
        ca-certificates \
        git \
    && rm -rf /var/lib/apt/lists/*
ENV CARGO_PROFILE_RELEASE_DEBUG=line-tables-only
COPY --from=planner /build/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release -p buzz-relay

# ─── Stage 4: web-builder (pnpm + vite) ────────────────────────────────────
FROM mirror.gcr.io/library/node:${NODE_VERSION}-${DEBIAN_VERSION} AS web-builder
WORKDIR /web

# Copy ALL workspace manifests + patches + .npmrc (if any) BEFORE source
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY web/package.json web/
COPY admin-web/package.json admin-web/
COPY desktop/package.json desktop/
COPY patches/ patches/

# Install pnpm and deps. Use --no-frozen-lockfile to tolerate lockfile drift.
# Remove the unused virtua patch from pnpm-workspace.yaml before install so
# pnpm does not fail with ERR_PNPM_UNUSED_PATCH.
RUN npm install -g pnpm@11.4.0 \
    && sed -i '/virtua@0.49.3/d' pnpm-workspace.yaml \
    && pnpm install --no-frozen-lockfile

# Copy the rest of the source and build ONLY the web workspace
COPY web/ web/
RUN pnpm --filter ./web build

# ─── Stage 5: runtime ──────────────────────────────────────────────────────
FROM mirror.gcr.io/library/debian:${DEBIAN_VERSION}-slim
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /build/target/release/buzz-relay /usr/local/bin/buzz-relay
COPY --from=web-builder /web/web/dist /web/dist
ENV BUZZ_BIND_ADDR=0.0.0.0:3000
ENV BUZZ_WEB_DIR=/web/dist
EXPOSE 3000
CMD ["buzz-relay"]
