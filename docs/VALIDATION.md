# Verification record · 9 October 2026

| Check | Result | Where |
|---|---|---|
| Flutter analysis | Clean | Local and CI |
| Flutter tests | 4 passed | Local and CI |
| Browser tests | 7 passed | Local and CI |
| Deno extraction/token/request tests | 5 passed | Local and CI |
| Backend TypeScript check | Passed with pinned SDK and lockfile | Local and CI |
| Browser production build | Passed | Local and CI |
| SQL authorization tests | 29 passed | Laptop and isolated CI Supabase |
| HTTP integration flow | Passed | Laptop and isolated CI Supabase APIs |
| HTTP Edge Function boundaries | Passed | Laptop and CI; missing AI key, owner checks and contact revocation |
| Real receiver browser flow | Passed | Isolated Brave, laptop API, temporary HTTPS, mobile viewport |
| Configured phone HTTPS API | Passed | Actual public proxy; password login, private upload/read, honest AI failure |
| Local public-proxy credential boundary | Passed | Real HTTPS; legacy forgery, privileged credentials, modified signatures and query overrides denied |
| Development port isolation | Passed | Explicit 127.0.0.1 API, database and local mail bindings on laptop |
| Android debug APK compilation | Passed | GitHub Actions |
| Dependency audit | Zero findings at implementation | Local npm audit |

The [CI run](https://github.com/ashuujha/kin/actions/runs/37903881796) checks database
ownership, forwarded-account rejection, expiry, revocation and publication limits.
It also rejects unrelated linked Google emails and unverified provider emails.
The HTTP test additionally exercises private image upload/download, metadata
return permissions, manual review, history, fixed snapshots, contacts and deletion.
It uses explicitly synthetic Google identity rows and local password login. It
does **not** demonstrate real Google OAuth. Browser unit tests mock API responses
to verify escaping, no record persistence, revocation clearing and timeout clearing.
The additional real-browser test renders actual selected medical responses,
rejects a forwarded account, observes revocation polling, verifies escaped notes
and non-persistence, then opens and revokes a signed-out contact card. It passed
over the temporary HTTPS receiver. Screenshots were visually checked at a 390px
mobile viewport. Those authenticated sessions use synthetic eligibility fixtures.

The [configured APK build](https://github.com/ashuujha/kin/actions/runs/37903925353)
passed for source `c2894adf68d7e371f33c8e39e0bd8571e986f75c`. It compiles separate
Android CPU builds with the temporary HTTPS backend/receiver and labelled local
password login. The earlier 0.1.0 preview opened a setup screen without backend
configuration. APKs are debug-signed, not Play Store releases. Physical installation,
Google PKCE return and the live two-account walkthrough remain pending.

The [0.1.1 local preview](https://github.com/ashuujha/kin/releases/tag/v0.1.1-local-preview)
is public. The ARM64 APK is 87.1 MiB and ARMv7 is 67.1 MiB. Both archives, CPU
libraries and compiled HTTPS client values were verified, and checksums are
published with the release. These remain local fictional-data debug builds.

Live Gemma extraction requires a configured model key and an actual fictional
image request. Neither supported provider has been called with a live key here.
No provider image support, clinical accuracy or real-patient safety claim is made.
Render deployment remains pending. A temporary HTTPS tunnel now serves the local
production receiver assets and a same-origin API proxy; it lasts only while the
laptop's local services and tunnel remain running.

After authorized disposable-cache cleanup, the laptop's Docker engine and local
Supabase stack were started successfully. Database and HTTP checks now pass there.
The HTTP checks also cover Edge Function owner authentication, an honest 503 when
AI is unconfigured, anonymous contact projection and rejection after revocation.
Synthetic identities now contain the timestamps and subject expected by Auth,
so fixtures remain readable by the real Auth API. See [LOCAL_DEMO.md](LOCAL_DEMO.md).

The interactive Graphify map is a development aid, not a security audit. Its report
lists parser/deduplication limitations and unavailable exact semantic token counts.
