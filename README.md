# Kin

A reviewed medical summary, shared with permission, opened in any browser.

[![CI](https://github.com/ashuujha/kin/actions/workflows/ci.yml/badge.svg)](https://github.com/ashuujha/kin/actions/workflows/ci.yml)
[![Android APK](https://github.com/ashuujha/kin/actions/workflows/android-build.yml/badge.svg)](https://github.com/ashuujha/kin/actions/workflows/android-build.yml)

Kin is a hackathon prototype. The Flutter Android owner app stores private
prescription images, extracts draft fields with Gemma and requires owner review.
Owners search reviewed medicine/date history and share only selected summaries.
The recipient uses a standard browser: Google-authenticated, view-only medical
access for 24 hours, or a separate anonymous contact-only QR.

**Use fictional records only.** Owner review is not clinical verification.
Kin does not diagnose, recommend treatment, predict risks or check interactions.

## Build status

The app, browser client, database access controls and model adapter are implemented.
Flutter, browser/backend and database checks pass, the local HTTP flow passes on
the laptop and in CI, and an installable Android debug APK compiles. The receiver
also passes real browser tests through temporary HTTPS. See [verification evidence](docs/VALIDATION.md).
The physical Android preview installs and local password login works, as reported
by the owner. The updated app adds consistent navigation, Google account creation
and sign-in UI, in-app privacy information and clear extraction errors.
Live Google OAuth, a live Gemma image call, permanent hosting and the complete
physical Android walkthrough remain pending. Local tests do not count as live
AI evidence. Consult CI and [docs/DEMO.md](docs/DEMO.md) before presenting a feature
as demonstrated.

## Repository

```text
apps/
  mobile/                Flutter Android owner app
    lib/app/             App lifecycle and theme
    lib/core/            Config, secure sessions, repository, common widgets
    lib/features/        Auth, prescriptions, summary, family, emergency contacts
    test/                Date, upload, token and configuration checks
  recipient-web/         TypeScript / Vite receiver
    src/                 Browser auth, rendering, permission/expiry handling
    tests/               Receiver boundary tests
supabase/
  migrations/            Tables, RLS, private storage and narrow SQL RPCs
  functions/             Authenticated Gemma extraction; anonymous contact projection
  tests/database/        Cross-user, forwarded-link, expiry and revocation checks
fixtures/                Visibly fictional test prescription and expected fields
scripts/                 Local setup, receiver proxy and real API/browser tests
docs/                    Scope, architecture, API, privacy, threat model, pitch and rules
graphify-out/            Interactive architecture graph, data and audit report
.github/workflows/       CI and installable debug APK build
```

## Local setup

Requirements: Node 22+, Docker, Flutter **3.47.7**. Java/Android SDK are needed for
local APK builds; GitHub Actions can build the APK without local Android tooling.
The isolated laptop starter also uses Python 3 and a local Unix Docker socket.
For the configured fictional phone demo and temporary HTTPS receiver, follow
[the local walkthrough](docs/LOCAL_DEMO.md).

```sh
npm ci
npm run local:start
```

Copy the local API URL and public anon key into the ignored
`apps/recipient-web/.env.local`, using `.env.example` as the template. Do not use
the service-role key in either client. `npm run local:configure` writes local
client profiles without printing credentials. The starter generates ignored
private signing keys, keeps CLI credential output private, and binds raw
development ports to localhost. Follow the local walkthrough for phone HTTPS.

```sh
npm run dev -w apps/recipient-web
```

In `apps/mobile`, copy `config.example.json` to ignored `config.json`, fill its
public values, and run:

```sh
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=config.json
```

For an emulator, replace `127.0.0.1` with `10.0.2.2` in the mobile Supabase URL.
For a phone use the computer's reachable LAN address, and bind local services
appropriately. HTTP and local password testing are debug-only development paths;
they are not a secure public sharing deployment. Google PKCE needs OAuth setup.

## Live services

Follow [the final app connection guide](docs/LAUNCH.md). It includes the exact
Google callback URLs and a checked `npm run production:configure` command. The
final profile uses hosted Supabase and a stable browser origin, verifies that
Google/signup are enabled, and disables local password login.

1. Create a Supabase project; apply migrations with `supabase db push`.
2. Configure Google OAuth in Supabase. Use its `/auth/v1/callback` URL in Google;
   allow exactly `dev.ashuujha.kin://auth/callback` and the receiver's HTTPS
   `/auth/callback`. Do not use wildcard production redirect URLs.
3. Configure Edge Function secrets using `supabase/.env.example`, then deploy
   `extract-prescription` and `emergency-contact`. Keep model/service keys server-side.
4. Create the Render static site from `render.yaml`, set the two public frontend
   variables, and set `ALLOWED_ORIGINS` to its exact HTTPS origin on the backend.
5. Set public GitHub repository variables `SUPABASE_URL`, `SUPABASE_ANON_KEY` and
   `RECIPIENT_URL`, then run Android APK. Optional workflow inputs override these
   public values. With no configuration the APK displays a truthful setup screen.
   The workflow creates separate APKs for each CPU architecture. Keep
   `local_test_login=false` for Google builds. APKs are debug-signed hackathon builds.
6. Perform the two-account live walkthrough in [docs/DEMO.md](docs/DEMO.md).

DigitalOcean Gemma model ID: `gemma-4-31B-it`, OpenAI-compatible image messages.
This adapter must pass a real fictional-image smoke test on the account before
claiming live support. Optional Google-hosted Gemma uses `gemma-4-31b-it` and is
restricted to fictional demonstrations under the provider's terms. No model is
fine-tuned by this project. There is no separate OCR or vector database.

## Checks

```sh
npm test
npm run check:backend
npm run build
npx supabase test db
npm run test:integration
```

In `apps/mobile`: `flutter analyze`, `flutter test` and
`dart format --output=none --set-exit-if-changed lib test`.

See [MVP](docs/MVP.md), [architecture](docs/ARCHITECTURE.md),
[security](docs/THREAT_MODEL.md), [privacy](docs/PRIVACY.md),
[pitch](docs/PITCH.md) and [event rules](docs/EVENT_RULES.md).

## Open source and attribution

Application code is MIT licensed. Gemma 4 is an open-weight model released under
Apache 2.0; hosted model use remains subject to provider terms. Kin sends an image
to Gemma for structured draft extraction and uses SQL for subsequent lookup.
No model weights are redistributed. See [LICENSE](LICENSE).

Built for MLH Hacktoberfest Hack Day x CYCODERS. AI-assisted development uses
Codex; documentation and code review remain the maintainer's responsibility.
Public code and a license make the project reviewable; prize eligibility still
depends on the event's rules and demonstrated use of the specified model.
