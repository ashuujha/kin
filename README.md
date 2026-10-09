# Kin

Project website: [kin-care-ten.vercel.app](https://kin-care-ten.vercel.app/) · [Documentation directory](https://kin-care-ten.vercel.app/docs/)

A reviewed medical summary, shared with permission, opened in any browser.

[![CI](https://github.com/ashuujha/kin/actions/workflows/ci.yml/badge.svg)](https://github.com/ashuujha/kin/actions/workflows/ci.yml)
[![Android APK](https://github.com/ashuujha/kin/actions/workflows/android-build.yml/badge.svg)](https://github.com/ashuujha/kin/actions/workflows/android-build.yml)

[Browser receiver](https://ashuujha.github.io/kin/) ·
[Signed Android release](https://github.com/ashuujha/kin/releases/tag/v0.2.1-hosted) ·
[Three manual account steps](docs/MANUAL_SETUP.md)

Kin is a hackathon prototype with a light Android workspace and side navigation.
Keep private prescriptions, laboratory PDFs and Drive/DICOM links together.
Gemma extracts private draft fields; owner review is required before sharing.
Private family invitations bind to a Google account for 24 hours. A separate,
explicitly enabled emergency QR opens selected medical information in a browser
without login. Anyone holding this QR can read the snapshot; originals remain private.

**Use fictional records only.** Owner review is not clinical verification.
Kin does not diagnose, recommend treatment, predict risks or check interactions.

## Build status

Signed Android release compilation, CI and browser deployment pass for 0.2.1.
Hosted checks cover private uploads, actual Gemma prescription/PDF extraction,
review, anonymous emergency access, cross-user denial, rotation and revocation.
The app connects to hosted services without the development laptop. Real Google
login return on a physical phone and the two-account walkthrough remain pending.
See [verification evidence](docs/VALIDATION.md).

Direct public HTTPS report-file links can be imported. Authenticated laboratory
portals require the owner to download the report first; Kin does not bypass login.
Drive/DICOM integration stores private links, without decoding or copying the files.

## Contribute to Kin

[Kin’s GitHub repository](https://github.com/ashuujha/kin) is currently public.
Developers and other contributors are welcome to suggest improvements, report
bugs, improve documentation and submit code. We maintain the app’s standards
through maintainer review, automated checks and controlled changes to the main
branch. Private medical records and service credentials are never contributions.

To contribute:

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the project’s privacy boundaries.
2. [Open an issue](https://github.com/ashuujha/kin/issues) to discuss an improvement,
   or fork the repository and make changes on a separate branch.
3. Submit a pull request describing the change and relevant verification.
4. GitHub automatically runs the configured CI checks on pull requests. Address
   feedback and check failures before a maintainer merges the contribution.

Merged contributions automatically become part of the GitHub main branch.
Existing workflows rebuild and deploy the browser receiver when its relevant
files change, and build Android APKs when mobile files change. Public APK releases
and the Vercel website still require their publishing/deployment steps.
Contributions are not automatically merged or released without review.

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
The quickest assisted path is [MANUAL_SETUP.md](docs/MANUAL_SETUP.md): save provider
credentials in ignored `.env.launch.local`, then run `npm run production:deploy`.
GitHub Pages already hosts the receiver, so Render is an optional alternative.

1. Create a Supabase project; apply migrations with `supabase db push`.
2. Configure Google OAuth in Supabase. Use its `/auth/v1/callback` URL in Google;
   allow exactly `dev.ashuujha.kin://auth/callback` and the receiver's HTTPS
   `/auth/callback`. Do not use wildcard production redirect URLs.
3. Configure Edge Function secrets using `supabase/.env.example`, then deploy
   `extract-prescription`, `extract-lab`, `emergency-medical` and `emergency-contact`. Keep model/service keys server-side.
4. Create the Render static site from `render.yaml`, set the two public frontend
   variables, and set `ALLOWED_ORIGINS` to its exact HTTPS origin on the backend.
5. Set public GitHub repository variables `SUPABASE_URL`, `SUPABASE_ANON_KEY` and
   `RECIPIENT_URL`, then run Android APK. Optional workflow inputs override these
   public values. With no configuration the APK displays a truthful setup screen.
   The workflow creates separate APKs for each CPU architecture. Keep
   `local_test_login=false` for Google builds. Public hosted APKs use the persistent release signing key.
6. Perform the two-account live walkthrough in [docs/DEMO.md](docs/DEMO.md).

DigitalOcean Gemma model ID: `gemma-4-31B-it`, OpenAI-compatible image messages.
This adapter must pass a real fictional-image smoke test on the account before
claiming live support. Optional Google-hosted Gemma uses `gemma-4-26b-a4b-it` and is
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
