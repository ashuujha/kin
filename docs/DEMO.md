# Demo and verification

Do not claim a live feature based on mocked data. Local tests use fictional
identities and synthetic fixtures; Google identity verification in SQL tests is
not an external OAuth login. The WhatsApp architecture screenshot is not input
medical evidence. Live provider credentials and public project URL are not yet
available in this development session.

Compiled APK and passing checks are recorded in [VALIDATION.md](VALIDATION.md).
The real local API integration test can be run after `supabase start` with
`npm run test:integration`; its Google eligibility rows are clearly synthetic.

## Three-minute walkthrough
1. Owner signs in using Google on the Android app.
2. Upload the visibly fictional typed prescription PNG from `fixtures`.
3. Run Gemma extraction live. If unavailable, show the honest error; label any
   manually entered record as manual and do not describe it as an AI result.
4. Compare draft fields with the image, confirm review and save.
5. Search Paracetamol for last calendar month. Show the resolved dates and the
   prescription's literal dosage, not a recommended/current dose.
6. Publish only selected medicines and an owner-reported allergy.
7. Invite a second Google account; open the link on a phone browser with no Kin
   installation. A third account must be denied even with the forwarded link.
8. Revoke the invitation. The next server check must fail and clear the browser.
9. Scan the separate public contact QR while signed out. Only contacts appear.
10. Rotate/revoke that QR and verify that the old link fails.

Explain that expiry is 24 hours **from creation**, not acceptance. Never edit the
clock/client to pretend production expiry has been demonstrated; use automated
database tests to verify the boundary and identify them as tests.

## Local testing
`npm test`, `npm run check:backend`, `npm run build`, `npx supabase test db` and
Flutter analysis/tests cover validation, month boundaries, owner isolation,
Google-identity recipient binding, expiry, revocation and projection boundaries.
Tests cannot establish handwriting accuracy, medical reliability, legal compliance,
provider endpoint image support or successful installation on a physical phone.

Local development password login is available only in non-release mobile builds
with `ALLOW_LOCAL_AUTH=true`. It is explicitly labelled as local testing and does
not bypass the production recipient RPC requirement for a confirmed Google identity.

## Pending live checks
- Actual Google login + Android deep-link return on the chosen physical phone.
- Actual Gemma request on the configured provider, using fictional input only.
- Public HTTPS browser callback, security headers and allowed-origin configuration.
- Phone upload/review, browser acceptance, polling revocation and contact scan.
