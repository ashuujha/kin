# Kin project website

Public project overview, Android preview downloads and documentation directory.

Production: https://kin-care-ten.vercel.app/
Documentation: https://kin-care-ten.vercel.app/docs/

## Run locally

From the repository root:

```sh
python3 -m http.server 5180 --bind 127.0.0.1 --directory apps/website
```

Open http://127.0.0.1:5180/. This is a static HTML, CSS and JavaScript site with no install or build step, no analytics and no application credentials.

## Structure

- `index.html`: product overview, workflow, sharing, privacy, public APK downloads and FAQ.
- `docs/index.html`: directory of the twelve maintained project guides on GitHub.
- `assets/`: Kin mark and actual Flutter screen captures.
- `style.css`: shared solid-colour design and responsive layouts.
- `script.js`: progressively enhanced scroll reveals; respects reduced motion.
- `vercel.json`: static deployment and security headers.
- `404.html`: branded missing-page response.

The screenshots were rendered from Kin’s real AuthScreen and HomeScreen widgets at 430 × 900 logical pixels. Home uses an empty document list, not fabricated patient records. Roboto and the SDK’s Material Icons were loaded for capture. The sign-in screenshot illustrates the interface; it does not demonstrate a successful Google OAuth session.

The primary ARM64 download points to https://kin-downloads.vercel.app/kin-0.1.2-local-arm64.apk, a separate static Vercel project with the identical versioned release APK. GitHub remains an alternative; ARMv7 downloads use GitHub. The mirror has an attachment filename and accepts byte-range requests for interrupted downloads. Keep APK binaries out of the source repository. The website clearly labels the debug-signed local-service preview and pending Google/AI setup. Update these claims only after an independently connected build and actual provider walkthrough succeed.

## Deploy

Vercel project: `kin-care` in the `ashuujha` team. The connected GitHub repository uses `apps/website` as its Root Directory, no framework, empty install/build commands and `.` as the output directory. The directory’s `vercel.json` carries the static settings and response headers. Vercel links are local ignored files.

Run from the linked repository root (the root `.vercelignore` excludes credentials, backend files and mobile builds):

```sh
npx vercel --prod
```

The recipient application remains separate at https://ashuujha.github.io/kin/; this website does not receive medical tokens or records.

## Validation

Actual Chromium/Brave checks passed at 1440, 390 and 320 pixel widths: screenshots load, no horizontal overflow, zero CSS gradients, download anchors, expandable FAQ, twelve documentation links and no JavaScript page errors. Reduced-motion preferences disable reveal animations. Signed-out production access, deployed screenshots, documentation routing and response headers are checked after publication.
