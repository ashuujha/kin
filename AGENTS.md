# Kin contributor instructions

Kin is a hackathon prototype for reviewed prescription records and consent-based sharing.
Use fictional medical records for development and demos. Never commit credentials or real records.

## Structure
- `apps/mobile`: Flutter Android owner app.
- `apps/recipient-web`: TypeScript browser receiver; no installation required.
- `supabase`: PostgreSQL migrations, RLS, Edge Functions and authorization tests.
- `fixtures`: visibly fictional prescriptions; `docs`: scope, security and demo guidance.

## Commands
- Root: `npm ci`, `npm test`, `npm run build`, `npm run check:backend`.
- Browser: `npm run dev -w apps/recipient-web`, `npm run typecheck -w apps/recipient-web`.
- Mobile: `flutter pub get`, `flutter analyze`, `flutter test` in `apps/mobile`.
- One Dart file: `dart format lib/path.dart`; one test: `flutter test test/path_test.dart`.
- Database: `npx supabase start`, `npx supabase test db` (Docker required).
- Backend tests: `npm run test:backend`; database tests must run before changing access policies.

## Boundaries
Read [docs/MVP.md](docs/MVP.md) and [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md).
Enforce ownership with RLS; do not rely on UI checks or trust client-provided owner IDs.
Google authentication verifies account control, not relationships or professional credentials.
Private originals and draft extraction never appear in recipient responses.
Medical shares expire 24 hours from creation; check revocation and expiry on every request.
Anonymous contact links contain no medical information.
AI output is untrusted draft data. Missing values stay unknown; owner review is not clinical verification.
Lookup reads reviewed records directly. Do not add vectors, agents, diagnosis or interaction advice.
Never describe a feature or provider call as working until it has been tested.

## Workflow
Keep dependencies locked, changes small and interfaces explicit. No unrelated cleanup.
Use parameterized database calls, escaped text, bounded uploads and sanitized errors.
Run checks relevant to changed code. Test cross-user reads, forwarded links, expiry and revocation.
Do not log records, email addresses, tokens, prompts, API keys or raw provider responses.
Document live-service setup and any untested integration honestly.
Include `Co-Authored-By: Codex (GPT-6) <noreply@openai.com>` on agent-authored commits.
