# Engineering Integration Report — muxa_xtream

This engineering report documents the `muxa_xtream` Dart package for other agents or engineering teams to integrate it into applications and automation. It covers architecture, public API, contracts, extension points, edge cases, tests, and security.

## 1. Package snapshot
- Package: `muxa_xtream`
- Version (library): 0.1.0
- Language: Dart (pure Dart package, SDK: ^3.8.1)
- Purpose: Xtream Codes / Xtream-API client offering account/server queries, catalogs (live/vod/series), details, EPG helpers, streaming M3U/XMLTV parsing, diagnostics and URL builders.

## 2. Architecture overview
- Public API barrel: `lib/src/api.dart` (exports client, models, adapters, parsers, URL builders).
- Client: `XtreamClient` (`lib/src/client.dart`) orchestrates requests to portal endpoints: `player_api.php`, `get.php`, `xmltv.php`.
- HTTP abstraction: `lib/src/http/` contains `XtHttpAdapter`, `XtRequest`, `XtResponse`, and platform adapter factories.
- Models: `lib/src/models/` contains typed domain models and JSON parsing.
- Parsers: `m3u/parser.dart` and `xmltv/parser.dart` provide streaming parsers emitting `XtM3uEntry` and `XtXmltvEvent` respectively.
- Utilities: `core/cancellation.dart`, `core/logger.dart`, `core/redaction.dart`, `core/errors.dart`.

Design points:
- Credentials are passed as query parameters in every request.
- Client exposes pluggable HTTP adapters and accepts a custom logger for integration flexibility.
- Streaming parsers return `Stream<T>` to allow incremental consumption and cancellation.

## 3. Public API & usage
Key types and functions (import `package:muxa_xtream/muxa_xtream.dart`):

- XtreamClient(portal, credentials, {options, http, logger})
  - getUserAndServerInfo(): Future<XtUserAndServerInfo>
  - getLiveCategories(), getVodCategories(), getSeriesCategories(): Future<List<XtCategory>>
  - getLiveStreams({categoryId}), getVodStreams({categoryId}), getSeries({categoryId})
  - getVodInfo(vodId), getSeriesInfo(seriesId)
  - getShortEpg({streamId?, epgChannelId?, limit}): Future<List<XtEpgEntry>>
  - ping(): Future<XtHealth>
  - capabilities(): Future<XtCapabilities>
  - getM3u(output='hls'): Stream<XtM3uEntry>
  - getXmltv(): Stream<XtXmltvEvent>

- XtreamPortal, XtreamCredentials, XtreamClientOptions, XtreamLogger
- HTTP primitives: XtHttpAdapter, XtRequest, XtResponse
- Error types: XtAuthError, XtPortalBlockedError, XtNetworkError, XtParseError, XtUnsupportedError

Minimal code sample:

```dart
final portal = XtreamPortal(Uri.parse('https://portal.example'));
final creds = XtreamCredentials(user: 'u', pass: 'p');
final client = XtreamClient(portal, creds);
final info = await client.getUserAndServerInfo();
```

## 4. Data contracts and error model
- Endpoints return JSON, usually arrays for catalogs and objects for details. The client decodes JSON and constructs typed models.
- Errors are thrown as domain-specific exceptions:
  - Authentication: `XtAuthError` (HTTP 401/403)
  - Portal blocked / captive: `XtPortalBlockedError` (HTTP 451 or HTML responses)
  - Network/HTTP failures: `XtNetworkError` (other non-2xx)
  - Parsing issues: `XtParseError` (invalid JSON or missing fields)
  - API misuse: `XtUnsupportedError` (e.g., missing required id for EPG)

The client attempts tolerant parsing but will throw `XtParseError` when essential fields are missing.

## 5. Extension points
- Custom HTTP adapter: pass your implementation of `XtHttpAdapter` to control retries, TLS, connection pooling, and headers.
- Custom logger: pass an `XtreamLogger` to capture or forward logs. The library provides `XtreamLogger.stdout()`.
- Cancellation tokens: pass `XtCancellationToken` to abort long-running requests or streaming parsers.

## 6. Edge cases and operational guidance
- Credentials in query: always use HTTPS and avoid logging full URLs. Redactor is used for logging but validate in integrations.
- EPG variability: servers may require `epg_channel_id`. Use `epgChannelId` when available; the client auto-retries.
- Parsers: `getM3u()` and `getXmltv()` return Streams — ensure consumers cancel or fully consume them to release resources.
- HTML or captive responses: treat as blocked or parse failures; handle `XtPortalBlockedError` explicitly.

## 7. Testing & CI
- Dev dependencies: `test`, `lints`.
- Suggested CI steps:
  1. Install Dart SDK compatible with `^3.8.1`.
  2. dart pub get
  3. dart analyze
  4. dart test --reporter=expanded

Use the `example/main.dart --mock` mode for network-free integration tests.

## 8. Security considerations
- Use HTTPS for portal endpoints.
- Store credentials securely (env vars or secrets manager).
- Avoid logging full response bodies; rely on redaction utilities.

## 9. Recommended next actions for integrators
- Add an integration test harness that stubs a portal's `player_api.php`, `get.php`, and `xmltv.php` responses; assert client behavior.
- Add a small GitHub Action to run `dart analyze` + `dart test` on PRs.
- Document JSON shapes for each model in `doc/model_contracts.md` for easier mapping by other systems.

## 10. Where to inspect code
- Public barrel: `lib/src/api.dart`
- Client orchestration: `lib/src/client.dart`
- HTTP adapters: `lib/src/http/`
- Models and parsers: `lib/src/models/`, `lib/src/m3u/`, `lib/src/xmltv/`
