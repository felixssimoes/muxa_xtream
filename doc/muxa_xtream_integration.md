# Integration Guide — muxa_xtream

This short guide shows how to add and use `muxa_xtream` from another Dart project. It focuses on integration points, configuration, and common pitfalls so other agents or developers can wire the package into applications or automation.

## Quick install
Add to your `pubspec.yaml`:

```yaml
dependencies:
  muxa_xtream: ^0.1.0
```

Then run:

```bash
dart pub get
```

If you're working with a local checkout during development, use a path dependency pointing to the package root.

## Basic usage (minimal)
Import and create the client:

```dart
import 'package:muxa_xtream/muxa_xtream.dart';

final portal = XtreamPortal(Uri.parse('https://portal.example:8080'));
final creds = XtreamCredentials(user: 'username', pass: 'password');

final client = XtreamClient(
  portal,
  creds,
  options: XtreamClientOptions(requestTimeout: const Duration(seconds: 15)),
  logger: XtreamLogger.stdout(),
);

// Example: ping and fetch first live category
final health = await client.ping();
final liveCategories = await client.getLiveCategories();
final channels = await client.getLiveStreams(categoryId: liveCategories.first.categoryId);
final url = client.urls.liveUrl(streamId: channels.first.streamId);
```

## Important integration details
- Credentials: the client sends `username` and `password` as query parameters on each request. Ensure you use HTTPS for portal URLs in production.
- Logging: library uses a `Redactor` to redact sensitive parts in logs, but avoid logging raw responses. Provide a custom logger if you need different behavior.
- Timeouts and retries: tune `XtreamClientOptions` or provide a custom `XtHttpAdapter` for advanced retry and TLS settings.
- Cancellation: long-running calls (M3U/XMLTV streams) accept `XtCancellationToken` to cancel parsing and free network resources.

## Handling EPGs
- Use `getShortEpg(streamId: ...)` or pass `epgChannelId` when known. The client will retry with `epgChannelId` if `stream_id` returns empty results.
- EPG responses vary per portal; be prepared for empty lists and missing fields.

## Streaming parsers
- `getM3u()` and `getXmltv()` return Streams of parsed entries. Always cancel the stream or fully consume it to avoid leaking connections.

## Error handling
Catch the library's consistent error types:
- `XtAuthError` — 401/403
- `XtPortalBlockedError` — portal blocked or captive page (HTTP 451)
- `XtNetworkError` — other non-2xx HTTP responses
- `XtParseError` — invalid or unexpected JSON
- `XtUnsupportedError` — misuse (e.g. missing parameters)

Example:

```dart
try {
  final cats = await client.getLiveCategories();
} on XtAuthError catch (e) {
  // refresh credentials or notify user
} on XtPortalBlockedError catch (e) {
  // portal blocked — inspect network or captive portal
} on XtParseError catch (e) {
  // malformed response
}
```

## Custom HTTP adapter
To control network behavior (timeouts, retries, TLS), pass your own `XtHttpAdapter` to the `XtreamClient` constructor:

```dart
final customHttp = MyCustomAdapter(...);
final client = XtreamClient(portal, creds, http: customHttp);
```

The package provides default adapters for IO/web platforms. See `lib/src/http` for adapter interfaces and `adapter_factory_*` implementations.

## Tests and local verification
- Run package tests: `dart pub get` then `dart test`.
- The `example/main.dart` supports `--mock` mode for testing without network calls. Use that to exercise the public API.

## Security recommendations
- Always use HTTPS for portal URIs.
- Store credentials in environment variables or secrets manager; avoid hard-coding.
- Do not log raw request/response bodies that may contain credentials or PII.

## Where to look in the codebase
- Public API / barrel: `lib/src/api.dart`
- Client: `lib/src/client.dart`
- HTTP adapters: `lib/src/http/`
- Models: `lib/src/models/`
- Parsers: `lib/src/m3u/` and `lib/src/xmltv/`

---

If you want, I can also add a tiny integration test harness (local HTTP stub) or a CI job to run analyze+tests automatically.
