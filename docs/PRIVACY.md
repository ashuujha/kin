# Prototype privacy notice

Use fictional records only. Kin is not ready for real patient information.

For the prototype, the owner chooses which prescription image to store, reviews
extracted fields and selects medicines, allergies and notes for publication.
Original images and drafts remain private to that account. Family access grants
cover a specific snapshot for 24 hours and can be revoked early. A separate
public contact QR intentionally reveals only the selected name/contact fields.
Recipients do not need an installed app, but require internet; medical recipients
must use the invited Google account.

An inference provider receives the prescription image during extraction. Review
that provider's terms, retention rules and allowed uses before configuring it.
Google's Gemini API terms prohibit submitting sensitive personal information to
unpaid services and prohibit clinical-practice/medical-advice uses across tiers.
A paid key alone does not resolve those use restrictions. DigitalOcean's hosted
model privacy documentation describes no storage/training of those inference
inputs/outputs; this does not establish that every related service has identical
retention or that Kin is authorized for clinical use.

No research-data sharing, data sales, clinical-trial matching or advertising is
implemented. Age and gender alone do not establish safe anonymization; any future
research program would need independent consent and a re-identification analysis.

No HIPAA, DPDP, medical-device approval or E2EE claim is made. Applicable duties
depend on jurisdiction, relationships, intended use and phased legal commencement.
Copies recipients have saved cannot be revoked. Operator logs/backups and account
erasure need a separate retention and deletion design before a public patient launch.

## Laboratory reports and emergency opt-in

Imported lab PDFs/images are private originals. Import requests AI extraction; the selected report or its text is sent to the configured provider. Use fictional reports in this hackathon. Draft results are saved automatically and require owner comparison before sharing. Source flags are copied, not independently interpreted.

Drive/DICOM links remain private records in Kin; accessing their files follows the source provider’s permissions. Kin does not store laboratory portal passwords or OTPs.

The separate emergency medical QR is disabled by default. If the owner opts in, anyone holding the QR can view its selected medical snapshot without login. This includes people who forward or photograph it. Original files, Drive URLs and private extraction excerpts are excluded. Revoke or replace the QR to stop future reads; already copied information cannot be recalled.
