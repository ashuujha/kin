# Threat model

| Threat | Control | Remaining limit |
|---|---|---|
| User changes a document ID | Database RLS; user JWT storage download; backend gets owned row | Provider admin/service key is privileged and must remain server-side |
| Forwarded medical link | Google identity must verify the invited primary email; recipient ID binding | Compromised recipient account can view its grants |
| Guessed QR/token | Random 256-bit tokens, SHA-256 at rest | Anyone who copies public contact QR can see contacts |
| Stale JWT after revocation | DB checks grant expiry/revocation on every read | Copies already made cannot be recalled |
| Browser persists health details | No records in browser storage, no-store headers, clear on background/failed checks | Screenshots and browser extensions remain outside control |
| Malicious document instructions | Fixed extraction-only prompt, no tools, JSON schema and owner review | Prompt injection/hallucination can still corrupt draft fields |
| Oversized or disguised file | 5 MB bucket cap, MIME allowlist, server/client signatures | No antivirus or full image-decoder sandbox; typed image scope only |
| Model key leaks | Server environment only; frontend public keys only | Operator access and provider compromise need operational controls |
| Anonymous endpoint abuse | Shared database rate counters, per-token and global limits | Conservative global cap can cause denial of service; no distributed WAF |
| Owner overshares accidentally | Explicit selected publication and fixed invitation snapshots | Users can still knowingly or accidentally publish sensitive notes |
| Mobile screenshots/backups | FLAG_SECURE; Android backup disabled; secure session/PKCE storage | Rooted/compromised devices and gallery originals are not protected |

No end-to-end encryption is claimed: the server and inference provider process
plaintext. TLS and provider storage encryption have different threat boundaries.
No medical payloads, prompts or bearer tokens are intentionally logged by Kin.
Managed platform request/access logging must still be reviewed before real use.

Audit records contain action, actor ID, resource ID and time only. Retention of
operational logs, backups and audit data requires policy/configuration before
production. Owner record deletion removes the storage object first, then metadata
and medicines; partial failure is retryable. There is no account-erasure UI yet.

Security checks are automated in `supabase/tests/database` and backend/web/mobile
tests. Passing them is not a penetration-test certification or legal compliance.

The recipient check uses server-managed `auth.identities` data. An unrelated linked
Google email or an unverified provider email is rejected even when the account's
primary email is confirmed. Supabase's [Google provider implementation](https://github.com/supabase/auth/blob/master/internal/api/provider/google.go)
returns the provider email and its verification status. Tests use synthetic rows;
the real OAuth callback still needs a configured provider and a live walkthrough.
