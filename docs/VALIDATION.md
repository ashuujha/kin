# Expanded workspace · 0.2.0 candidate

Flutter analysis and ten tests passed, including direct-link validation, private-network rejection, side navigation and emergency consent. The drawer and emergency-consent tests cover a 320px-wide phone and a disabled publish action until owner consent. The dark sign-in/home screens were rendered and checked at 320px and 390px; actual images replace the previous screenshots. Signed Android compilation and the physical-device Google walkthrough are pending.

Hosted database checks passed: all 29 existing authorization assertions plus 16 new linked-file, laboratory and opt-in emergency assertions. Tests ran in rolled-back fictional-fixture transactions. The migration and extraction/emergency endpoints are deployed.

A real hosted PDF/Gemma request extracted the fictional blood-report fixture, including glucose 110 mg/dL and its literal high flag. The expanded hosted HTTP flow passed private Drive references, PDF upload, cross-user denial, extraction, owner review, anonymous selected medical access, exclusion of original paths/private excerpts/Drive links, token rotation, revocation and deletion invalidation. Temporary test sessions are not proof of physical-device Google login.

Dr Lal PathLabs’ report portal was researched; it requires Lab/Visit ID and password. The app offers a portal shortcut and imported-file extraction. It does not claim an authorized automatic lab connector or automatic access to private Drive content.

# Reference UI release · 0.1.4

The [signed Android build](https://github.com/ashuujha/kin/actions/runs/37926670811) passed analysis, six Flutter tests and release compilation from `9efdbb42550156bb263c60d3fc53631d9f08f6c2`. The [publishing job](https://github.com/ashuujha/kin/actions/runs/37927329084) uploaded all three CPU builds and checksums directly from GitHub. The [public release](https://github.com/ashuujha/kin/releases/tag/v0.1.4-hosted) is available. ARM64 is 19,390,720 bytes; ARMv7 is 16,897,740 bytes.

The full public ARM64 download matched its SHA-256. Archive CRCs, ARM64 libraries, compiled hosted URL and the persistent signing certificate were verified. It can update the signed 0.1.3 hosted app. Older debug builds require removal first.

The reference-based redesign uses white surfaces, pale green highlights, dark pill buttons, compact sharing cards and an original medical-record illustration. Actual Flutter sign-in/home renders were exported and visually reviewed; both 320px and 390px layouts passed overflow checks. The website uses those actual images with versioned image URLs. Hosted services and the remaining physical-device Google walkthrough status below still apply.

# Hosted release status · 9 October 2026

The signed [0.1.3 hosted build](https://github.com/ashuujha/kin/actions/runs/37922512583) passed release compilation, Flutter analysis and tests. ARM64 is 19,390,840 bytes; ARMv7 is 16,897,864 bytes. Archive CRCs, CPU libraries, compiled hosted Supabase URL and the persistent distribution certificate were checked. Public APKs and SHA-256 checksums are attached to the [prerelease](https://github.com/ashuujha/kin/releases/tag/v0.1.3-hosted). Uninstall older debug-signed previews before installing.

Hosted Supabase migrations and both Edge Functions are deployed. All 29 SQL authorization checks passed against the hosted database in a rolled-back fictional-fixture transaction. The [browser receiver deployment](https://github.com/ashuujha/kin/actions/runs/37922433025) uses hosted public client configuration.

A real Google Gemma call extracted one Paracetamol medication and the expected date from the visibly fictional typed-image fixture. Six backend regression tests and TypeScript checks passed after filtering reasoning parts and rejecting incomplete responses. This establishes provider connectivity and schema handling, not medical accuracy. AI remains a draft requiring owner review.

Downloaded Google web-client credentials were applied privately. An invalid-code credential probe returned `invalid_grant`, confirming credential acceptance. After the Google redirect setting was saved, a fresh authorization request opened the Google account sign-in page without `redirect_uri_mismatch` or an OAuth error page. The Google authorized redirect URI is `https://wbhjgppzyhqlagjxyzrn.supabase.co/auth/v1/callback`. Real Google account return, physical-device installation and an actual two-account hosted walkthrough remain pending. These are not represented as completed.

The public hosted ARM64 download was verified end to end: 19,390,840 bytes, matching SHA-256, APK attachment headers and a successful HTTP 206 range request. The website passed desktop, mobile and 320px browser checks, screenshot loading, download visibility, FAQ, documentation, overflow and reduced-motion checks. The live receiver passed homepage/privacy rendering and invitation-to-Google navigation in an isolated mobile-size browser; no account login was performed.

The prior local verification record below is historical; its local-only service and missing-key statements describe earlier builds.

# Earlier local verification record

| Check | Result | Where |
|---|---|---|
| Flutter analysis | Clean | Local and CI |
| Flutter tests | 6 passed after final UI changes | Local; preceding CI had 4 |
| Browser tests | 8 passed after mounted-path support | Local; preceding CI had 7 |
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

The [CI run](https://github.com/ashuujha/kin/actions/runs/37915515356) checks database
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

The [updated configured APK build](https://github.com/ashuujha/kin/actions/runs/37913587802)
passed for source `a2dc4d12ecd78fc711c9bb86e3fe091ea00b3f63`. It compiles separate
Android CPU builds with the temporary HTTPS backend/receiver and labelled local
password login. The earlier 0.1.0 preview opened a setup screen without backend
configuration. APKs are debug-signed, not Play Store releases. The user reports
successful physical installation and local password login on Android. The phone
shows an extraction failure, consistent with the independently tested 503 for
the empty model key. Manual review and contact sharing on that physical device,
Google PKCE return and the live two-account walkthrough remain pending.

The [0.1.2 local preview](https://github.com/ashuujha/kin/releases/tag/v0.1.2-local-preview)
is public. The ARM64 APK is 87.1 MiB and ARMv7 is 67.1 MiB. Both archives, CPU
libraries and compiled HTTPS client values were verified, and checksums are
published with the release. These remain local fictional-data debug builds.

Live Gemma extraction requires a configured model key and an actual fictional
image request. Neither supported provider has been called with a live key here.
No provider image support, clinical accuracy or real-patient safety claim is made.
The [permanent browser receiver](https://ashuujha.github.io/kin/) deployed successfully
in [its hosting run](https://github.com/ashuujha/kin/actions/runs/37915515367).
Homepage, privacy, invitation and OAuth callback paths return HTML successfully.
An isolated mobile browser confirmed actual page rendering and the truthful
missing-backend state. This public deployment is not connected to hosted Supabase
yet. Render deployment remains an optional alternative. A temporary HTTPS tunnel serves the local
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

The 0.1.2 source adds consistent mobile navigation, a Google account-entry screen,
privacy information and bounded extraction error messages. The configuration
guard confirms hosted Google/signup settings before generating public client
profiles. The user confirmed hosted Supabase/Google setup is still needed, and no
AI key is present. These changes do not establish live OAuth or extraction.

The hosted HTTP integration subsequently passed private upload, cross-user denial,
actual Gemma draft extraction, owner review, history lookup, recipient snapshot,
forwarded-account rejection, revocation, signed-out contacts and deletion.
Temporary fictional users and files were cleaned up. Authentication in this test
used admin-issued sessions and an explicitly synthetic Google identity; it does
not establish real Google OAuth or physical-device behavior.
