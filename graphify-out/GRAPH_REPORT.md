# Graph Report - /home/ashu/Projects/kin  (2026-10-09)

## Corpus Check
- Corpus is ~21,578 words - fits in a single context window. You may not need a graph.

## Summary
- 524 nodes · 763 edges · 37 communities (31 shown, 6 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.84)
- Token cost: unmetered; exact Codex semantic-extraction usage is unavailable

## Community Hubs (Navigation)
- Product security and delivery
- Owner data access
- Browser receiving
- Prescription review
- Gemma extraction and contacts
- Navigation and Google sign-in
- Secure configuration and sessions
- Browser dependencies
- Database access and grants
- Private prescription screens
- Emergency contact editing
- Workspace tooling
- App session lifecycle
- Prescription history lookup
- Summary publication
- Shared mobile widgets
- Browser type checking
- Family invitations
- Flutter stateful screens
- Local API integration tests
- Fictional prescription fixture
- Backend type configuration
- Android device privacy
- Calendar date logic
- Hackathon rules and prizes
- Browser rendering tests
- Flutter template HDPI icon
- Flutter template MDPI icon
- Flutter template XHDPI icon
- Flutter template XXHDPI icon
- Flutter template XXXHDPI icon

## God Nodes (most connected - your core abstractions)
1. `Kin project overview` - 16 edges
2. `loadSummary()` - 14 edges
3. `Real local Supabase HTTP integration evidence` - 14 edges
4. `Threat model` - 12 edges
5. `Architecture` - 11 edges

## Surprising Connections (you probably didn't know these)
- `Pull request validation` --semantically_similar_to--> `Contributing guide`  [INFERRED] [semantically similar]
  .github/pull_request_template.md → CONTRIBUTING.md
- `Kin contributor instructions` --semantically_similar_to--> `Agent contributor instructions`  [INFERRED] [semantically similar]
  AGENTS.md → agent.md
- `Kin contributor instructions` --semantically_similar_to--> `Claude contributor instructions`  [INFERRED] [semantically similar]
  AGENTS.md → CLAUDE.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Selected publication and authorized browser snapshot** — docs_api_publish_summary, docs_api_medical_sharing_rpcs, docs_mvp_medical_share, docs_architecture_recipient_browser [EXTRACTED 1.00]
- **Private image to reviewed structured history** — docs_architecture_flutter_owner_app, docs_architecture_private_image_bucket, docs_architecture_authenticated_extraction_function, docs_mvp_owner_review, docs_mvp_structured_history_lookup [EXTRACTED 1.00]
- **Prototype code requires separate live evidence** — readme_pending_live_verification, docs_demo_live_walkthrough, docs_demo_synthetic_test_limits, docs_event_rules_best_use_of_gemma_4 [INFERRED 0.85]
- **CI evidence combines real local APIs with synthetic identities** — docs_validation_ci_evidence, docs_validation_local_http_integration, docs_demo_synthetic_test_limits, docs_validation_ci_environment_fallback [EXTRACTED 1.00]

## Communities (37 total, 6 thin omitted)

### Community 0 - "Product security and delivery"
Cohesion: 0.07
Nodes (70): Reproducible bug reports, Bounded feature requests, Pull request validation, Installable debug-signed Android APK, Android APK workflow, Web/backend, database and mobile checks, Continuous integration workflow, Agent contributor instructions (+62 more)

### Community 1 - "Owner data access"
Cohesion: 0.05
Nodes (40): app_config.dart, client, contactLink, contacts, deleteDocument, documentMedications, documents, extract (+32 more)

### Community 2 - "Browser receiving"
Cohesion: 0.16
Nodes (31): brand, captured, clearDisplay(), footer, header, heading(), key, loadContacts() (+23 more)

### Community 3 - "Prescription review"
Cohesion: 0.07
Nodes (28): build, busy, bytes, clinic, createState, date, delete, dispose (+20 more)

### Community 4 - "Gemma extraction and contacts"
Cohesion: 0.19
Nodes (17): extract(), Draft, DraftMedication, imageMime(), parseDraft(), text(), authenticated(), clients() (+9 more)

### Community 5 - "Navigation and Google sign-in"
Cohesion: 0.09
Nodes (22): app/app.dart, kinTheme, showLink, AuthScreen, _AuthScreenState, build, busy, configured (+14 more)

### Community 6 - "Secure configuration and sessions"
Cohesion: 0.08
Nodes (23): AppConfig, _localAuth, recipientUrl, supabaseKey, supabaseUrl, accessToken, getItem, hasAccessToken (+15 more)

### Community 7 - "Browser dependencies"
Cohesion: 0.09
Nodes (22): dependencies, @supabase/supabase-js, devDependencies, jsdom, typescript, vite, vitest, name (+14 more)

### Community 8 - "Database access and grants"
Cohesion: 0.12
Nodes (10): auth, auth.users, public, private.audit_events, private.rate_limits, public.contacts, public.documents, public.medications (+2 more)

### Community 9 - "Private prescription screens"
Cohesion: 0.10
Nodes (20): source, build, createState, HomeScreen, _HomeScreenState, initState, open, records (+12 more)

### Community 10 - "Emergency contact editing"
Cohesion: 0.11
Nodes (18): build, ContactEditor, contacts, createState, dispose, form, initState, link (+10 more)

### Community 11 - "Workspace tooling"
Cohesion: 0.11
Nodes (17): deno, devDependencies, deno, supabase, name, private, scripts, build (+9 more)

### Community 12 - "App session lifecycle"
Cohesion: 0.12
Nodes (16): build, configured, createState, dispose, initState, KinApp, _KinAppState, navigator (+8 more)

### Community 13 - "Prescription history lookup"
Cohesion: 0.12
Nodes (16): RecordMap, build, createState, initState, loadNames, medicine, names, query (+8 more)

### Community 14 - "Summary publication"
Cohesion: 0.12
Nodes (15): KinRepository, build, createState, dispose, form, initState, load, loading (+7 more)

### Community 15 - "Shared mobile widgets"
Cohesion: 0.13
Nodes (15): build, busy, BusyButton, child, friendlyError, icon, KinCard, label (+7 more)

### Community 16 - "Browser type checking"
Cohesion: 0.12
Nodes (15): compilerOptions, lib, module, moduleResolution, noEmit, skipLibCheck, strict, target (+7 more)

### Community 17 - "Family invitations"
Cohesion: 0.13
Nodes (14): build, busy, create, createState, dispose, email, initState, invites (+6 more)

### Community 18 - "Flutter stateful screens"
Cohesion: 0.27
Nodes (10): ContactScreen, _ContactScreenState, FamilyScreen, _FamilyScreenState, HistoryScreen, _HistoryScreenState, SummaryScreen, _SummaryScreenState (+2 more)

### Community 19 - "Local API integration tests"
Cohesion: 0.22
Nodes (6): admin, anon, clients, config, options, userIds

### Community 20 - "Fictional prescription fixture"
Cohesion: 0.25
Nodes (8): Fictional dosage: 500 mg, Fictional duration: 4 weeks, Example Clinic (fictional software test), Fictional Demo Person, Fictional frequency: as written in this fictional example, Fictional typed prescription fixture dated 2026-09-03, OCR and review tests, Paracetamol (fictional prescription entry)

### Community 21 - "Backend type configuration"
Cohesion: 0.29
Nodes (6): compilerOptions, strict, fmt, lineWidth, imports, @supabase/supabase-js

### Community 22 - "Android device privacy"
Cohesion: 0.40
Nodes (3): MainActivity, Bundle, FlutterActivity

### Community 23 - "Calendar date logic"
Cohesion: 0.40
Nodes (4): calendarMonth, end, previous, start

### Community 24 - "Hackathon rules and prizes"
Cohesion: 0.70
Nodes (5): Best Open-Source AI Project, Best Use of Gemma 4, Event and prize research, Hacktoberfest Hack Day Barasat x CYCODERS Club, MLH open-source AI guidance

## Knowledge Gaps
- **233 isolated node(s):** `configured`, `navigator`, `subscription`, `createState`, `initState` (+228 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `KinRepository` connect `Summary publication` to `Owner data access`, `Prescription review`, `Private prescription screens`, `Emergency contact editing`, `Prescription history lookup`, `Family invitations`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `RecordMap` connect `Prescription history lookup` to `Owner data access`, `Prescription review`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **Why does `route()` connect `Browser receiving` to `Gemma extraction and contacts`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
## Extraction health and interpretation

This graph maps developer context; it is not a security audit or clinical search index.

The raw extraction had 11 unresolved import references and 23 same-endpoint connections collapsed by the undirected graph, including 11 exact duplicate edges. No missing endpoint fields or self-loops were found.

Unresolved references include external Supabase/Vitest/Node imports and a CSS import.
Data-only config.example.json and typed-example.json produced no AST nodes.
Overloaded Dart symbols and the SVG/PNG representations of the same fictional
prescription share deterministic IDs; some distinct contexts collapse. Template
launcher icons are still Flutter-branded and appear as separate small communities.

One parser-inferred route() → text() connection crosses the browser and backend
source files because of a shared function name. It is not a verified runtime call.
Treat inferred edges and weak-community scores as navigation clues, not defects.
The auth replacement migration supersedes the initial accept_share definition;
the graph represents both source definitions rather than migration execution order.

## Accounting note

Semantic extraction used Codex-session workers. Exact input/output usage is not
exposed by this host. Zero counters in cost.json are compatibility placeholders,
not a claim of free extraction. Corpus/query benchmark numbers are token estimates
for developer-context retrieval, not measured application latency or medical accuracy.
