# Kin pitch pack

Tagline: **A reviewed medical summary, shared with permission, opened in any browser.**

## Thirty seconds
Medical records are spread across files, clinics and phones. Families often need
the context from those records, but sharing an entire folder exposes too much.
Kin extracts a prescription into a draft, asks the owner to review it and lets
them share only a selected summary. The recipient uses a browser and the invited
Google account, with access ending after 24 hours. A separate public QR gives
emergency contacts only. Original records remain private.

Use “we are building” until the live walkthrough in DEMO.md passes. Describe local
automated checks as tests, never as a successful live clinical deployment.

## Three-minute judge pitch
Imagine helping a parent at an appointment. Their prescriptions are in different
folders, and you need to find what was written last month. Sending every document
to every person is both inconvenient and unnecessarily revealing.

Kin gives the owner a private place for prescription images. Gemma turns a clear
typed prescription into structured draft fields. The owner compares each field
with the source before saving it. Unknown fields stay unknown. We label records
as owner reviewed, not clinically verified, and a prescription never proves what
someone is currently taking.

The owner can search reviewed history by medicine and prescription date. AI runs
once during ingestion; lookup reads structured records directly. Different doses
remain separate, and no model chooses a correct or current dose.

For family sharing, the owner selects medicines, reports allergies and publishes
a summary. An invitation captures those selected details, belongs to a specific
Google account and expires 24 hours after creation. The recipient opens it in a
normal browser without installing Kin. Revocation is checked at the database on
every read. Full prescriptions and unselected history stay private.

Emergency access has a narrower boundary. A separate public QR reveals chosen
contacts without login. It does not expose a medical profile, unlock a phone or
make a DNR decision. This is an online prototype, with explicit practical limits.

The code is public and MIT licensed; Gemma 4 provides meaningful open-model
extraction. We want to validate whether this review and permission flow makes
care coordination easier. We have not measured clinical outcomes or launched to
real patients. Our next step is usability testing and independent clinical/legal
review before considering real medical information.

## Six slides
1. Problem: fragmented records; oversharing full folders.
2. Flow: private image → extraction draft → owner review → selected summary.
3. AI: Gemma extraction once; source comparison; unknown values preserved.
4. Permission: invited Google account, fixed snapshot, 24-hour expiry, revoke.
5. Live proof: two-account browser demo plus separate contact QR; identify tests.
6. Next validation: review mistakes, caregiver usability, clinical-use boundary.

## Questions and honest answers
| Question | Answer |
|---|---|
| What exactly works? | Consult CI and DEMO.md. Implemented code is distinct from live integrations awaiting credentials. |
| Why another medical-record app? | We focus on owner-reviewed prescription context and deliberately small, temporary browser shares. ABHA and other systems already address personal records/consent sharing. |
| Is this an emergency medical system? | The emergency path provides public contacts only. It does not authorize treatment or expose a full medical record. |
| What if the patient is unconscious? | A reachable printed/contact QR can identify contacts. Private summary access requires an existing recipient grant and their login. |
| What about a locked phone? | Kin does not bypass it or claim automatic lock-screen integration. |
| Does a receiver install anything? | No. A browser and internet suffice; medical access also requires the invited Google account. |
| Is the AI diagnosing? | No. It drafts literal fields for owner review. No predictions, interaction checks or advice. |
| Does AI run on every query? | No. Ingestion only; medicine/date lookup queries reviewed structured records. |
| Why no vector RAG? | The chosen question type is structured lookup. An extra index/model call adds complexity without improving this bounded MVP. |
| What is your AI accuracy? | No validated accuracy figure yet. Typed English image scope and human review do not establish clinical reliability. |
| Can you read messy handwriting? | No reliable claim. The initial scope is clear typed English JPEG/PNG prescriptions. |
| What if extraction fails? | Visible failure, retry or clearly labelled manual entry. No manufactured AI result. |
| What if values conflict? | Show each prescription/date separately; do not infer the right dose. |
| Does prescription duration prove active use? | No. Taking/stopped states are owner-reported, separately labelled. |
| Are allergies inferred? | No, the owner enters them. Empty means not recorded, not absence. |
| Can an attacker change an ID? | RLS and ownership checks deny other users' records/storage; test the denial rather than trusting the UI. |
| Can I forward a share? | The forwarded token cannot grant access to a different Google identity/email. |
| Does Google verify a doctor/family member? | It verifies account control only. Professional/family verification is deferred. |
| When does expiry start? | Creation, exactly 24 hours; accepting later does not extend it. |
| What if their JWT is still valid? | Each read checks the grant deadline and revocation independently. |
| Can revoked data be erased? | Future requests stop; screenshots/copies cannot be recalled. |
| Do future publications change old shares? | No. Invitations hold snapshots. Reviewing/deleting sources revokes existing medical shares conservatively. |
| Is the public QR private? | Contacts are intentionally visible to anyone possessing it. No medical fields are returned. |
| Does the QR work offline? | No. The receiver uses online browser access. NFC/offline/PDF paths are deferred. |
| Is this end-to-end encrypted? | No. TLS/storage encryption differ from E2EE; the server/model processes plaintext. |
| Is it HIPAA/DPDP compliant? | No such claim. Applicability and obligations require independent review before real use. |
| Is a non-diagnostic disclaimer enough? | No. Intended use and clinical workflow determine regulatory/provider constraints. |
| Can unpaid Gemini receive real records? | No. Provider terms prohibit sensitive uploads and clinical-use categories; a paid tier alone does not settle those restrictions. |
| What is stored in the browser? | Auth/PKCE and pending invitation material in session storage; no medical payloads. |
| Can you sell anonymized data? | No research sharing/data sales in the MVP. Age/gender do not establish anonymity. |
| Why Flutter/Supabase/Render? | One owner codebase, managed Google auth/RLS/private storage, and standard HTTPS static receiver. |
| Why not use every sponsor credit? | More providers create more integration work. Use inference credits if eligible; reserve the others. |
| Is there a revenue model? | Future subscription hypothesis for storage/caregiver conveniences. No billing, revenue, validated price or market-size claim. |
| Who is the initial audience? | Adults coordinating their own records with trusted adult caregivers. Minor/guardian delegation is deferred. |
| What about ABHA/FHIR? | Potential interoperability work; no integration/FHIR-compliance claim in this build. |
| Is it an open-source AI entry? | It can qualify after a real meaningful Gemma demo, public license/setup and organizer rule checks. Public visibility alone is insufficient. |
| Did you train Gemma? | No. We use hosted inference; no model weights/training dataset are redistributed. |
| What is the biggest unresolved risk? | Whether users can review extraction errors reliably, followed by account/service configuration and real-use governance. |
| What evidence would justify expansion? | Measured extraction error rates, caregiver task success, clinical review and operational privacy controls. |

## Mentor request
Help us assess which fields caregivers actually need, which extraction errors
owners are likely to miss, and whether the consent/expiry flow is understandable.
We want feedback on the care-coordination workflow before making clinical claims.
