# Connect the final hackathon app

The app has Google account creation/sign-in, private prescription storage,
extraction with owner review, history, selected family invitations and a separate
contact QR. A recipient uses a normal browser. Live Google and AI require the
accounts below; the old local password preview does not provide those services.

## 1. Create the hosted backend

Create a free [Supabase project](https://supabase.com/dashboard). Record its public
project URL, project reference and publishable/anon key. Keep its database password
and server keys private. Sign into the CLI, then apply Kin's migrations:

```sh
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
npx supabase functions deploy extract-prescription --project-ref YOUR_PROJECT_REF
npx supabase functions deploy emergency-contact --project-ref YOUR_PROJECT_REF
```

Use a new Kin project. The migrations create tables, private storage and access
policies. CLI prompts accept the database password without putting it in source.
The deployed functions verify user identity themselves. Their JWT gateway settings
are already declared in `supabase/config.toml`.

## 2. Deploy the browser receiver

In [Render](https://dashboard.render.com/), create a Blueprint from
`https://github.com/ashuujha/kin`. The committed `render.yaml` builds a static site
and supplies HTTPS, SPA routes and security headers. Enter the project's public
URL/key as `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. The blueprint explicitly
enables Google and disables the local development proxy.

Save the resulting stable `https://…onrender.com` origin. The public homepage and
`/privacy` page can be used in the Google consent configuration. This deployment
does not need a receiver app installation or a laptop tunnel.

## 3. Connect Google once for both apps

Follow [Supabase's Google setup](https://supabase.com/docs/guides/auth/social-login/auth-google).
In Google Cloud / Google Auth Platform:

1. Configure the app name **Kin**, your support email, homepage and privacy URL.
2. Request only `openid`, email and basic profile scopes.
3. Create an OAuth client with type **Web application**. Kin uses the browser
   OAuth/PKCE flow on Android; a native Google SDK and Android SHA fingerprint are
   not required for this flow.
4. Authorized JavaScript origin: your stable receiver origin.
5. Authorized redirect URI: `https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback`.
6. Put the client ID and secret in **Supabase → Authentication → Sign In / Providers
   → Google**, then enable Google. Keep new-user signups enabled. The first Google
   sign-in creates the account; later sign-ins open the same account.

In **Supabase → Authentication → URL Configuration**, set Site URL to the receiver
origin and add exactly these redirect URLs:

```text
https://YOUR_RECEIVER.onrender.com/auth/callback
dev.ashuujha.kin://auth/callback
```

Choose a Google audience/publishing status that permits the intended users. If
Google's app is in Testing, explicitly add both demo accounts and any judge who
will sign in. Publishing or branding verification is controlled by Google; do not
assume a code change bypasses it.

## 4. Connect real AI extraction

Create a DigitalOcean [model access key](https://docs.digitalocean.com/products/inference/how-to/manage-model-access-keys/)
scoped to `gemma-4-31B-it`. Confirm inference funding on the actual account.
Put these server values in ignored `supabase/.env.production.local`:

```dotenv
AI_PROVIDER=digitalocean
AI_MODEL=gemma-4-31B-it
AI_API_KEY=YOUR_MODEL_ACCESS_KEY
ALLOWED_ORIGINS=https://YOUR_RECEIVER.onrender.com
```

Then upload them to the hosted function environment:

```sh
npx supabase secrets set --env-file supabase/.env.production.local --project-ref YOUR_PROJECT_REF
```

No server, Google secret or model key belongs in the mobile app, receiver, GitHub
workflow inputs or chat. Use the visibly fictional fixture for the hackathon.

## 5. Generate and build the configured app

Copy root `.env.production.example` to ignored `.env.production.local` and fill
in the three public values. Run:

```sh
npm run production:configure
```

This verifies the hosted project's public key, enabled Google provider and
signup setting, then writes `apps/mobile/config.production.json` and the browser's
production environment. It refuses service keys and temporary tunnel addresses.
It does not count as an actual OAuth or model call.

Build with Java/Android SDK available:

```sh
cd apps/mobile
flutter build apk --debug --split-per-abi --dart-define-from-file=config.production.json
```

Alternatively dispatch the repository's **Android APK** GitHub workflow with
the three public values and leave **local_test_login=false**. The workflow's
installable APK is debug-signed for direct hackathon distribution; it is not a
Play Store release. Do not install an unconfigured artifact expecting live login.

## Ready means the connections work

The final walkthrough is: Google sign-in → upload the fictional image → actual
Gemma draft → owner review → history → publish selection → named Google recipient
opens the browser link → revoke. A separate signed-out contact QR shows contacts
only. Automated checks already cover isolation, expiry and revocation; these
account connections still need one actual walkthrough before claiming live readiness.
