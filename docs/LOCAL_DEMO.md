# Local Android and browser walkthrough

This profile uses real local Supabase APIs and private storage, a labelled fictional
password account, and a standard browser receiver. It does not demonstrate Google
OAuth or live Gemma. Medical invitations still require a verified Google identity;
they are not opened to anonymous users to make the demo easier.

## Start the backend

Requirements: Node 22+, Docker, and the repository's locked dependencies.

```sh
npm ci
npx supabase start -x studio,logflare,vector,imgproxy,realtime,postgres-meta
npm run local:configure -- 127.0.0.1
npx supabase functions serve --env-file supabase/.env.local
```

Keep the function command running. The configure helper creates a fictional owner
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
APIs under `/backend`. It does not expose the Vite development server, repository
files, signup or admin auth routes. Original-file reads still need an owner JWT
and pass storage RLS. Local password login is intended for fictional tests.

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
throughout the phone test. A LAN-only alternative uses the laptop's private IPv4
address in `local:configure`; that path is debug HTTP, not secure public sharing.

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
3. Extraction should report that AI is not configured. Enter the fictional
   prescription fields manually, review them, and save. Search the reviewed
   medicine and the explicit prescription date.
4. Publish a summary with selected fields. A private medical invitation can be
   created, but signed-out browser acceptance correctly stops at the unconfigured
   Google sign-in boundary in this profile.
5. Create a separate contact card using clearly fictional contact details. Open
   its link in Chrome without installing a receiver app. Never call the fictional
   number. Revoke the card and confirm its previous link becomes unavailable.

Only the contact-card path is a complete anonymous phone-to-browser demo without
OAuth configuration. The private medical path has separate real API/browser tests
using explicitly synthetic eligibility fixtures. To demonstrate real recipient
account acceptance, complete Google setup and the walkthrough in [DEMO.md](DEMO.md).

## Verification

```sh
npx supabase test db
KIN_TEST_AI_UNCONFIGURED=1 npm run test:integration
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
