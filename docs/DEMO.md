# Demo and verification

Do not claim a live feature based on mocked data. Local tests use fictional
identities and synthetic fixtures; Google identity verification in SQL tests is
not an external OAuth login. The WhatsApp architecture screenshot is not input
medical evidence. Hosted Supabase, Google configuration and AI extraction are connected. See the current validation record for actual service checks and the remaining phone walkthrough.

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
- Physical-phone lab PDF import and extraction (hosted fictional PDF/Gemma check passed).
- Public HTTPS browser callback, security headers and allowed-origin configuration.
- Phone upload/review, browser acceptance, polling revocation and contact scan.

## Expanded workspace demo

Open the side navigation. Save a fictional Drive/DICOM link and show that only its owner can see it. Explain that large imaging files remain in the user’s own Drive, with its access permissions.

Import `fixtures/labs/fictional-blood-report.pdf` or its public direct-file link. AI automatically creates draft test/value/unit/range fields and a source-based summary. Compare the draft with the original, approve it, and open the saved report. The glucose high flag is explicitly printed in the fictional source; Kin does not infer a diagnosis.

Publish a selected summary, open Emergency medical QR, select the reviewed lab report, and explicitly enable the public-access checkbox. Scan this separate QR in a signed-out browser: selected medical data appears without installation or Google login. Explain that anyone holding this opt-in QR can read it; it is not limited to verified doctors. Revoke it and show access ending. Private family invitations remain a distinct Google-bound route.

The Dr Lal PathLabs button opens its actual password-protected portal. Download through the provider’s own flow, then import the PDF. Do not present this as an automated provider API integration.
