# API contracts

All user RPCs require a Supabase authenticated session. Ownership is derived from
the JWT and never accepted as an input. Return objects omit fields not needed by
their consumers. Errors are rendered as text and never returned as raw AI output.

| Interface | Input | Behavior |
|---|---|---|
| Private storage `prescriptions` | `user-id/document-id.jpg` or `.png` | Owner-only JPEG/PNG, 5 MB max |
| `extract-prescription` POST | `{document_id}` | JWT identity + owned file; signature check; draft Gemma JSON |
| `review_document` RPC | ID, optional Rx date/clinic, literal medication fields | Replaces reviewed medicines; records review time; invalidates shares |
| `search_prescriptions` RPC | Optional medicine, inclusive Rx start/end date | Reviewed owner matches + undated count; limit 200 entries |
| `publish_summary` RPC | Name, allergy strings, notes, selected medication IDs | Only owner-reviewed medicine IDs accepted |
| `create_share` RPC | Recipient email, token SHA-256 | Snapshot ID/deadline; exactly 24 hours from creation |
| `accept_share` RPC | Token SHA-256 | Confirmed Google identity must match invited email; returns share ID |
| `read_shared_summary` RPC | Share ID | Selected snapshot if recipient ID, expiry and revocation pass |
| `revoke_share` RPC | Share ID | Owner only; next read fails |
| `save_contacts` RPC | Name, contact objects, token hash or null | Allowlisted fields only; null revokes; new token rotates |
| `emergency-contact` POST | `{token}` | Anonymous rate-limited contact-only projection |
| `delete_document` RPC | Owned ID | Deletes metadata/medicines, invalidates publication/shares; remove storage first |

Medical links: `/s#<random-token>`. Contact links: `/e#<random-token>`.
Tokens stay out of query strings and are removed from the address bar before API
calls. Pending invitation tokens and auth session/PKCE material use tab-scoped
session storage. Medical records themselves are never stored there.

Medical shares are snapshots. Source edits/deletion revoke them; later publication
does not silently replace their content. Reading never exposes file URLs, drafts,
private excerpts or full owner history. Taking/stopped states are owner-reported.
