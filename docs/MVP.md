# Scope and acceptance

Kin: a reviewed medical summary, shared with permission, opened in any browser.

The owner uses Flutter Android with Google OAuth (PKCE). A private JPEG or PNG
prescription (one clear typed English page, maximum 5 MB) is extracted once by
Gemma. The owner compares draft fields with the original before saving. Unknown
fields remain empty. Manual entry is labelled. No clinical verification is claimed.

Reviewed prescription history supports medicine names and explicit prescription
date ranges. Undated matches are reported separately. Search does not invoke AI,
infer generic equivalents or select a dose from conflicting records.

The owner publishes selected reviewed medicines, manually entered allergies and
notes. A named Google account can view that summary in an ordinary browser for
24 hours from link creation. Owner revocation takes effect on the next request.
Original files, extraction drafts and full prescription history remain private.

A separate public QR exposes chosen emergency contact names, relationships and
phone numbers only. It remains active until rotated or revoked. Anyone with that
QR can view those contacts. Both receiver paths require internet.

## Expanded scope · 0.2.0

The owner can keep private HTTPS references to Google Drive files/folders and large DICOM archives. Kin does not upload, decode or interpret DICOM files; source-provider permissions apply. A linked file is not included in a medical share.

Laboratory imports accept text-based PDFs (up to 10 pages / 5 MB) and JPEG/PNG images. Direct publicly downloadable HTTPS report links can be imported on the phone; login pages require the owner to download the file first. Dr Lal PathLabs’ portal requires its own Lab/Visit ID and password, so a portal shortcut plus file import is provided rather than claiming automated portal access. No portal passwords or OTPs are stored.

Import triggers AI extraction into a private draft of literal test names, results, units, reference ranges and explicit source flags. A deterministic source-based summary describes those fields without diagnosis. Owner review promotes the draft to the structured report timeline. No vector search or semantic medical interpretation is claimed.

A separate emergency medical QR is disabled by default. An explicit owner opt-in publishes the selected medical summary and selected reviewed lab results to anyone with the unguessable QR token, without Google login. It is not doctor-only access. Originals, Drive links, patient identifiers extracted from PDFs and private source excerpts are excluded. Tokens are hashed; rotation, revocation and source deletion stop subsequent reads. The snapshot remains active until revoked or replaced and requires internet. Private family invitations retain their account binding and 24-hour expiry.

## Completion gates
1. Cross-user database/storage access denied; wrong Google account denied.
2. Upload, actual model extraction, review, history, publish and delete work.
3. Two accounts demonstrate browser acceptance, 24-hour expiry and revocation.
4. Contact QR works in a signed-out browser and never returns medical fields.
5. Android APK, web build, automated checks and deployment instructions exist.

Live Google OAuth and live model calls need provider configuration. Local tests
use clearly identified synthetic responses and never count as live AI evidence.

## Deferred
Diagnosis, interaction warnings, predictions, DNR decisions, medical advice,
research/data sales, minors/guardian delegation, offline/NFC, DICOM interpretation,
voice, insurance, billing, wearables, hospital integration and conversational RAG.
