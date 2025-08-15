# Development Plan & Progress

This document tracks implementation progress for the muxa_xtream package. Phases carry a status label: `todo | in progress | done`. Tasks within a phase are simple checkboxes.

## Phase 0 — Bootstrap — Status: `done`
- [x] Scaffold package layout and exports
- [x] Add `tool/verify.sh` (pub get, format check, analyze, tests+coverage)
- [x] Run baseline verification (`bash tool/verify.sh`)

## Phase 1 — Public Surface — Status: `done`
- [x] Implement core types (`XtreamPortal`, `XtreamCredentials`, `XtreamClientOptions`, `XtFeatures`)
- [x] Implement error taxonomy (`XtError`, `XtAuthError`, `XtNetworkError`, `XtParseError`, `XtPortalBlockedError`, `XtUnsupportedError`)
- [x] Implement `XtreamLogger` and redaction utilities
- [x] Add unit tests for errors and redaction

## Phase 2 — HTTP Transport — Status: `done`
- [x] Define `XtreamHttpAdapter` interface (GET/HEAD, headers, timeouts)
- [x] Implement default adapter (retries for GET, jitter backoff, redirects, TLS/self-signed, header injection, redaction)
- [x] Enable injectable transport for VM/Web
- [x] Add unit tests (timeouts, retries, redirects, headers, redaction)

## Phase 3 — Models & Parsing — Status: `done`
- [x] Implement models: user/server, categories, live/vod/series, details, EPG, capabilities
- [x] Add resilient JSON parsing with UTC normalization
- [x] Add golden/fixture tests (null/variant fields, fork tolerance)

## Phase 4 — URL Builders (no I/O) — Status: `done`
- [x] Implement `liveUrl`, `vodUrl`, `seriesUrl` (default HLS; TS fallback)
- [x] Optional: probe helper (HEAD/Range) for extension inference
- [x] Add unit tests for URL shapes and defaults

## Phase 5 — Client Core — Status: `done`
- [x] Implement account info: `getUserAndServerInfo`
- [x] Implement catalogs: live/vod/series categories and lists
- [x] Implement details: `getVodInfo`, `getSeriesInfo`
- [x] Implement short EPG: `getShortEpg(streamId, limit)`
- [x] Implement `ping()` and `capabilities()`
- [x] Add unit/contract tests (success/failure: 401/403/blocked/network/HTML error; large lists)

## Phase 6 — Optional M3U — Status: `done`
- [x] Implement `get.php` fetch and streaming parser
- [x] Map entries to models where feasible
- [x] Add tests (variants, malformed lines)

## Phase 7 — Optional XMLTV — Status: `done`
- [x] Implement isolate-based SAX parser with streaming, cancellation, backpressure
- [x] Emit `XtXmltvEvent` stream
- [x] Add tests (small fixtures; fetch)

## Phase 8 — Reliability & Security — Status: `done`
- [x] Wire cancellation/timeout plumbing across client
- [x] Centralize redaction; ensure no secrets in errors/logs
- [x] Polish error classification and messages
- [x] Add tests (cancel propagation, timeout classification, redaction)

## Phase 9 — Documentation — Status: `done`
- [x] Update README (quick start, examples, capability notes)
- [x] Add dartdoc comments for public API
- [x] Add Troubleshooting and Security Notes; link `AGENTS.md`

## Phase 10 — Tooling & CI — Status: `done`
- [x] Finalize `tool/verify.sh` and ensure local parity
- [x] Add CI workflow (format, analyze, test, coverage)

## Phase 11 — Versioning & Release — Status: `done`
- [x] Update `CHANGELOG.md`; bump version to `0.1.0`
- [x] Run `flutter pub publish --dry-run` and address findings
- [x] Tag release notes


## Phase 12 — Release & Publish — Status: `todo`
- [ ] Push `main` and tag `v0.1.0` to origin
- [ ] Publish to pub.dev (manual confirmation; 2FA as required)
- [ ] Create GitHub Release with highlights and links to README
- [ ] Add shields/badges (pub version, likes, CI) to README

## Phase 13 — Examples & Guides — Status: `todo`
- [ ] Expand `example/` to cover live, VOD, and series end-to-end flows
- [ ] Add a "Cookbook" section in README (URL builders, retries, redaction)
- [ ] Document common portal quirks and troubleshooting playbook

## Phase 14 — Adapters & Integrations — Status: `todo`
- [ ] Provide `package:http` adapter implementation
- [ ] Provide `dio` adapter implementation
- [ ] Add a lightweight mock adapter utilities module for tests

## Phase 15 — Catch‑up/Timeshift (Exploratory) — Status: `todo`
- [ ] Research portal support variations and required params
- [ ] Extend URL builders for timeshift paths
- [ ] Minimal contract tests where feasible

## Phase 16 — Per‑request Overrides — Status: `todo`
- [ ] API for per‑request headers and User‑Agent overrides
- [ ] Wire overrides through builders/adapters safely
- [ ] Docs and examples for providers that require custom headers

## Phase 17 — Caching & Rate Limiting — Status: `todo`
- [ ] Define a lightweight cache interface (user‑supplied storage)
- [ ] Detect `429`/throttling and add adaptive backoff
- [ ] Tests for backoff policy and cache plumbing

## Phase 18 — Performance & Benchmarks — Status: `todo`
- [ ] Micro‑benchmarks for parsing and builders
- [ ] Large catalog memory/latency profiling
- [ ] XMLTV throughput and backpressure tuning

## Phase 19 — Discovery & Extras (Optional module) — Status: `todo`
- [ ] Prototype MAC/Stalker discovery as a separate package
- [ ] Assess feasibility and compliance considerations

## Phase 20 — v1.0.0 Hardening — Status: `todo`
- [ ] Issue triage and stability fixes from early adopters
- [ ] Public API audit; any breaking changes queued for 1.0
- [ ] Final docs pass (README, dartdoc); publish `1.0.0`
