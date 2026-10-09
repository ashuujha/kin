# Contributing

Read [AGENTS.md](AGENTS.md) and [docs/MVP.md](docs/MVP.md). Use fictional records
and never attach personal medical documents to issues or pull requests.

Install Node 22+, Flutter stable and Docker. Run `npm ci`, `npm test`,
`npm run build`, `npm run check:backend`, `npx supabase start` and
`npx supabase test db`. In `apps/mobile`, run `flutter pub get`,
`flutter analyze` and `flutter test`.

Explain the behavior changed and relevant test results in pull requests.
Access-control changes require cross-user database tests. Disclose AI-assisted
development. Report vulnerabilities using [SECURITY.md](SECURITY.md).
