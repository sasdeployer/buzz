# buzz — before this ships

Two lists, split by who can actually close the item.

## Needs code — the coding agent

- [ ] Handle MinIO bucket creation without the one-shot minio-init container (`deploy/compose/compose.yml`)
      _deploy/compose/compose.yml depends on a run-to-completion minio-init (mc) service that creates the buzz-media bucket; the platform rejects one-shot pods, and without the bucket media uploads fail._
- [ ] Provision RELAY_OWNER_PUBKEY and BUZZ_RELAY_PRIVATE_KEY before first deploy (`deploy/compose/.env.example`)
      _deploy/compose/.env.example marks the owner pubkey and stable relay private key as required for closed-relay mode; deploying without them leaves auth/membership enforcement unconfigured._
- [ ] Build the drafted image(s) once and fix what fails; check `nexlayer.yaml`.

## Needs the human

- [ ] Decide: Is Keycloak actually required for any production auth flow, or is Nostr-based auth (NIP-42/98) sufficient? The compose only runs it in dev-mem mode.
- [ ] Decide: Should media move from the bundled MinIO to an external S3 provider at scale?
- [ ] `TYPESENSE_API_KEY` — the human adds it in the app's Secrets: <http://localhost:3001/apps/86fa4f48-3d73-45f2-9629-94b7c3c55fde/keys>
- [ ] `KEYCLOAK_ADMIN_PASSWORD` — the human adds it in the app's Secrets: <http://localhost:3001/apps/86fa4f48-3d73-45f2-9629-94b7c3c55fde/keys>

Never through the chat or this repo. `nexlayer.yaml` references each one as
`${NAME}`; Nexlayer fills it at deploy.

## Check after the deploy — the coding agent

- [ ] GET / on the app URL returns 200 and serves the buzz-web bundle
- [ ] GET /_readiness via the relay health port (8080) through internal networking returns 200 after migrations complete
- [ ] A WebSocket connection to the app URL (wss) completes the Nostr handshake (REQ/EVENT round-trip)
- [ ] Upload a file through the relay media API and confirm the object appears in MinIO (bucket buzz-media)
- [ ] Confirm Typesense answers search queries from the relay (channel/message search returns results after events are written)

---

Machine-readable: `.nexlayer/findings.json`.
