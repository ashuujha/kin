# Verification record · 9 October 2026

| Check | Result | Where |
|---|---|---|
| Flutter analysis | Clean | Local and CI |
| Flutter tests | 4 passed | Local and CI |
| Browser tests | 7 passed | Local and CI |
| Deno extraction/token/request tests | 5 passed | Local and CI |
| Backend TypeScript check | Passed with pinned SDK and lockfile | Local and CI |
| Browser production build | Passed | Local and CI |
| SQL authorization tests | 29 passed | Real local Supabase instance in CI |
| HTTP integration flow | Passed | Real local Supabase APIs in CI |
| Android debug APK compilation | Passed | GitHub Actions |
| Dependency audit | Zero findings at implementation | Local npm audit |

The [CI run](https://github.com/ashuujha/kin/actions/runs/37896988451) checks database
ownership, forwarded-account rejection, expiry, revocation and publication limits.
It also rejects unrelated linked Google emails and unverified provider emails.
The HTTP test additionally exercises private image upload/download, metadata
return permissions, manual review, history, fixed snapshots, contacts and deletion.
It uses explicitly synthetic Google identity rows and local password login. It
does **not** demonstrate real Google OAuth. Browser display tests mock API responses
to verify escaping, no record persistence, revocation clearing and timeout clearing.

The [APK build](https://github.com/ashuujha/kin/actions/runs/37894791881) compiles the
owner app. Public backend/receiver variables are unset, so this build opens the
setup screen. It is debug-signed, not a Play Store release. Physical-phone
installation, Google PKCE return and the live two-account walkthrough remain pending.

Live Gemma extraction requires a configured model key and an actual fictional
image request. Neither supported provider has been called with a live key here.
No provider image support, clinical accuracy or real-patient safety claim is made.
Render deployment and public HTTPS receiver behavior remain pending configuration.

The user's laptop Docker engine became unresponsive during initial image downloads;
disk space was low. The local Supabase stack could not be verified there. Database
and HTTP flow evidence therefore comes from CI's isolated local Supabase instance.

The interactive Graphify map is a development aid, not a security audit. Its report
lists parser/deduplication limitations and unavailable exact semantic token counts.
