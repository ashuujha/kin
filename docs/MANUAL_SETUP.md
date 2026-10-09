# The three manual account steps

The account owner must complete provider login/consent and create credentials.
Code cannot substitute for those permissions. No secrets should be sent in chat.

## Supabase

Sign in at https://supabase.com/dashboard and create a **free**, dedicated project
named **Kin**. Save its project reference and database password. Create a personal
access token at https://supabase.com/dashboard/account/tokens. A scoped token needs
project settings/API keys/API key secrets read access, Auth configuration write,
Edge Functions write and project secrets write for this deployment.

Put `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF` and `SUPABASE_DB_PASSWORD` in
the ignored root `.env.launch.local` on the laptop. The template is
[.env.launch.example](../.env.launch.example). This is a server-side operator file,
not an app configuration file. A new paid plan or billing upgrade is unnecessary.

## Google OAuth

In https://console.cloud.google.com/ create/select a project and open Google Auth
Platform. Configure **Kin** with your support email and basic `openid`, email and
profile scopes. Create an OAuth client of type **Web application**.

Use:

```text
Authorized JavaScript origin: https://ashuujha.github.io
Authorized redirect URI: https://YOUR_PROJECT_REF.supabase.co/auth/v1/callback
Homepage: https://ashuujha.github.io/kin/
Privacy: https://ashuujha.github.io/kin/privacy/
```

Replace only the project reference in the Google redirect URI. Put
`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env.launch.local`.
If the Google consent audience is in Testing, add the owner and recipient/judge
accounts as test users. An audience that permits the intended accounts is required
even when the app's code is complete. Google branding verification is separate.

## DigitalOcean AI

Use the MLH account credits if eligible. In the DigitalOcean inference dashboard,
create a model access key scoped to **Gemma 4 / `gemma-4-31B-it`** and choose **No
VPC network** for requests from this laptop/Supabase. Confirm actual inference
funding. Put the key in `AI_API_KEY` in `.env.launch.local`.

## Automated work after those inputs exist

From the project root, run `npm run production:deploy` (or ask the agent to run it).
The helper checks the dedicated project, applies migrations, configures Google
and exact callbacks, uploads server-only model secrets, deploys both functions,
retrieves only the public anon key, generates client profiles, configures public
GitHub variables and dispatches receiver/APK builds. It never prints credentials
or raw service responses and stops on incomplete inputs or a rejected stage.

The public browser receiver uses GitHub Pages; no extra Render account/token is
required for that deployment. Render remains available via `render.yaml` if needed.
Pages hosts the static client; medical data comes from authenticated APIs and is
not embedded in static HTML. GitHub Pages cannot provide the custom HTTP security
headers in the Render blueprint, so this remains a fictional-data hackathon setup.

Real OAuth, actual Gemma extraction and recipient acceptance must be observed
before presenting them as working. The old local preview remains usable for manual
review/history and contact sharing while these account inputs are missing.
