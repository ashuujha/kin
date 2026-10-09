# Local Android and browser walkthrough

This profile uses real local Supabase APIs and private storage, a labelled fictional
password account, and a standard browser receiver. It does not demonstrate Google
OAuth or live Gemma. Medical invitations still require a verified Google identity;
they are not opened to anonymous users to make the demo easier.

## Start the backend

Requirements: Node 22+, Docker with a local Unix socket, Python 3, and the
repository's locked dependencies. The explicit binding helper was tested on this
Linux laptop with Docker Desktop.

```sh
npm ci
npm run local:start
npm run local:configure -- 127.0.0.1
npx supabase functions serve --env-file supabase/.env.local --network-id kin-loopback
```

Keep the function command running. The starter creates private Auth signing
keys and stable API credentials in ignored `supabase/signing-keys.local.json` and
root `.env`, both with owner-only permissions. It binds raw API, database and mail
ports explicitly to localhost. Gateway configuration is preserved in local Docker
snapshots during binding; those contain credentials and must never be published
to a registry. Startup CLI output stays in ignored
`supabase/.temp/local-start.log` and must not be shared.

The configure helper creates a fictional owner
and writes its credentials to the ignored root `.env.local` with owner-only file
permissions. It writes only the public anon key to client configuration. Existing
provider secrets are preserved. Do not paste credentials or CLI status output into
issues or chat.

In another terminal:

```sh
npm run build
npm run local:receiver -- 0.0.0.0
```

The receiver serves production assets on port 5173 and proxies the required local
APIs under `/backend`. It accepts only verified ES256 user sessions signed by the
project's private key or an exact public anon identifier. Legacy user/service
tokens, privileged API keys, query credential overrides and signed-storage routes
are rejected. It translates an older preview's exact public anon identifier to
the current upstream anon credential; that identifier grants no user identity or
extra permissions. Original-file reads still require owner RLS. It exposes neither
the Vite server nor repository files, signup or admin auth routes.

CLI development defaults include public signing credentials. The project creates
private replacements and checks the proxy's public boundary. See the
[CLI defaults](https://github.com/supabase/cli/blob/v2.120.0/apps/cli-go/pkg/config/config.go)
and [official local network guidance](https://supabase.com/docs/guides/local-development).
Raw services must stay local. Use this profile for fictional tests.

## Use a temporary HTTPS address

With Docker Desktop, a Cloudflare Quick Tunnel can reach the receiver:

```sh
docker run --rm --name kin-receiver-tunnel cloudflare/cloudflared:latest tunnel \
  --no-autoupdate --protocol http2 --url http://host.docker.internal:5173
```

Use the printed `https://…trycloudflare.com` origin in the next command. On native
Linux Docker, configure a reachable host gateway instead of assuming Docker
Desktop's hostname exists. Quick Tunnels are temporary testing endpoints and stop
with the process; they are not production hosting.

```sh
npm run local:configure -- 127.0.0.1 https://YOUR-TUNNEL.trycloudflare.com
```

The Android configuration now points to the HTTPS `/backend` endpoint. The receiver
uses its own origin, so browser API requests stay on HTTPS. A new tunnel hostname
requires a new configured APK. Keep Docker, functions, receiver and tunnel running
throughout the phone test. The isolated starter intentionally prevents direct
phone access to raw Supabase ports. Use the HTTPS receiver for this walkthrough.

## Build and install Android

With Java and the Android SDK installed:

```sh
cd apps/mobile
flutter pub get --enforce-lockfile
flutter build apk --debug --split-per-abi --dart-define-from-file=config.local.json
```

Without local Android tools, dispatch the repository's **Android APK** workflow.
Its optional inputs accept the three public values from `config.local.json` and
`local_test_login=true`. Never put a service-role key, provider key or password in
workflow inputs. Download the `kin-android-debug` artifact. Most current physical
Android phones use `app-arm64-v8a-debug.apk`; an older 32-bit phone may need the
`armeabi-v7a` build. APKs are debug-signed. If an earlier preview reports a signature
conflict, remove that preview before installing; this clears its local session.

## Test on the phone

1. Open Kin. Confirm **Local testing · fictional account** is visible, then sign
   in using the fictional account in the laptop's ignored `.env.local`.
2. Download `fixtures/prescriptions/typed-example.png` from the public repository
   onto the phone. Upload it as an image in Kin. Use no real medical records.
3. Tap **Extract with Gemma**. This profile has no model key, so extraction shows
   **AI is not configured for this build** and offers manual entry. The earlier
   0.1.1 preview shows a generic extraction failure for the same missing key.
   Enter the fictional
   prescription fields manually, review them, and save. Search the reviewed
   medicine and the explicit prescription date.
4. Publish a summary with selected fields. A private medical invitation can be
   created, but signed-out browser acceptance correctly stops at the unconfigured
   Google sign-in boundary in this profile.
5. Create a separate contact card using clearly fictional contact details. Open
   its link in Chrome without installing a receiver app. Never call the fictional
   number. Revoke the card and confirm its previous link becomes unavailable.

## Enable real AI extraction

The current local configuration has an empty `AI_API_KEY`. Repeated extraction
attempts cannot fix missing configuration. Manual entry, review and history work
without AI; do not present manual entries as model output.

Create a DigitalOcean [model access key](https://docs.digitalocean.com/products/inference/how-to/manage-model-access-keys/)
scoped to Gemma 4, with **No VPC network** for requests from this laptop.
The [supported model identifier](https://docs.digitalocean.com/products/inference/details/models/)
is `gemma-4-31B-it`. Confirm the account has inference funding; the hackathon
credit amount alone does not establish this account's inference balance.
Set these values in the ignored `supabase/.env.local`, keeping existing allowed
origins:

```dotenv
AI_PROVIDER=digitalocean
AI_MODEL=gemma-4-31B-it
AI_API_KEY=YOUR_MODEL_ACCESS_KEY
```

Keep the secret out of chat, Git, client configuration and workflow inputs.
Restart the running Edge Functions command so it reloads this file, then retry
the visibly fictional fixture. The existing phone APK can use the newly
configured backend without a rebuild. A successful response still needs owner
review before it can become part of a published summary. Live extraction remains
unverified until that provider call succeeds.

Only the contact-card path is a complete anonymous phone-to-browser demo without
OAuth configuration. The private medical path has separate real API/browser tests
using explicitly synthetic eligibility fixtures. To demonstrate real recipient
account acceptance, complete Google setup and the walkthrough in [DEMO.md](DEMO.md).

## Verification

```sh
npx supabase test db
KIN_TEST_AI_UNCONFIGURED=1 npm run test:integration
KIN_PROXY_ORIGIN=https://YOUR-TUNNEL.trycloudflare.com npm run test:proxy
KIN_RECEIVER_ORIGIN=https://YOUR-TUNNEL.trycloudflare.com npm run test:receiver:live
```

The browser test uses isolated Brave by default; override `KIN_BROWSER_EXECUTABLE`
for an installed compatible Chromium browser. It creates and deletes fictional
fixtures, checks actual HTTPS API responses, wrong-account denial, escaped content,
record non-persistence, revocation polling and signed-out contact rendering. Its
mobile-viewport screenshots stay in ignored `test-results/`. Synthetic Google
identity rows are test fixtures, not a successful OAuth login or doctor validation.

For isolated CI, `KIN_INTEGRATION_START_FUNCTIONS=1` lets the integration test start
and stop its function runtime. Do not set this while a separate function server is
already running. Stop the tunnel to remove public access; stop local services when
finished. Follow [VALIDATION.md](VALIDATION.md) for observed results and pending work.

Before changing local credentials, stop functions and the receiver, run
`npx supabase stop`, then `npm run local:start`. After a CLI restart, use the
starter or `npm run local:bind` to reapply and verify explicit localhost bindings.
Do not reset the database as part of this walkthrough. A new backend key can be
used by a newly configured APK; the existing preview's public identifier remains
compatible through the local proxy while its ignored phone profile is retained.
