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

## Phase 2 — HTTP Transport — Status: `in progress`
- [x] Define `XtreamHttpAdapter` interface (GET/HEAD, headers, timeouts)
- [x] Implement default adapter (retries for GET, jitter backoff, redirects, TLS/self-signed, header injection, redaction)
- [x] Enable injectable transport for VM/Web
- [ ] Add unit tests (timeouts, retries, redirects, headers, redaction)

## Phase 3 — Models & Parsing — Status: `todo`
- [ ] Implement models: user/server, categories, live/vod/series, details, EPG, capabilities
- [ ] Add resilient JSON parsing with UTC normalization
- [ ] Add golden/fixture tests (null/variant fields, fork tolerance)

## Phase 4 — URL Builders (no I/O) — Status: `todo`
- [ ] Implement `liveUrl`, `vodUrl`, `seriesUrl` (default HLS; TS fallback)
- [ ] Optional: probe helper (HEAD/Range) for extension inference
- [ ] Add unit tests for URL shapes and defaults

## Phase 5 — Client Core — Status: `todo`
- [ ] Implement account info: `getUserAndServerInfo`
- [ ] Implement catalogs: live/vod/series categories and lists
- [ ] Implement details: `getVodInfo`, `getSeriesInfo`
- [ ] Implement short EPG: `getShortEpg(streamId, limit)`
- [ ] Implement `ping()` and `capabilities()`
- [ ] Add unit/contract tests (success/failure: 401/403/blocked/network/HTML error; large lists)

## Phase 6 — Optional M3U — Status: `todo`
- [ ] Implement `get.php` fetch and streaming parser
- [ ] Map entries to models where feasible
- [ ] Add tests (variants, malformed lines)

## Phase 7 — Optional XMLTV — Status: `todo`
- [ ] Implement isolate-based SAX parser with streaming, cancellation, backpressure
- [ ] Emit `XtXmltvEvent` stream
- [ ] Add tests (small fixtures, cancellation, resource sanity)

## Phase 8 — Reliability & Security — Status: `todo`
- [ ] Wire cancellation/timeout plumbing across client
- [ ] Centralize redaction; ensure no secrets in errors/logs
- [ ] Polish error classification and messages
- [ ] Add tests (cancel propagation, timeout classification, redaction)

## Phase 9 — Documentation — Status: `todo`
- [ ] Update README (quick start, examples, capability notes)
- [ ] Add dartdoc comments for public API
- [ ] Add Troubleshooting and Security Notes; link `docs/AGENTS.md`

## Phase 10 — Tooling & CI — Status: `todo`
- [ ] Finalize `tool/verify.sh` and ensure local parity
- [ ] Add CI workflow (format, analyze, test, coverage)

## Phase 11 — Versioning & Release — Status: `todo`
- [ ] Update `CHANGELOG.md`; bump version to `0.1.0`
- [ ] Run `flutter pub publish --dry-run` and address findings
- [ ] Tag release notes
