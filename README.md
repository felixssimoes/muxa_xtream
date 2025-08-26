<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

## muxa_xtream

An ergonomic Dart client for Xtream Codes IPTV portals. It provides strongly-typed models, resilient HTTP, URL builders for streams, EPG helpers, and optional M3U/XMLTV utilities. Designed to be reliable, secure, and easy to integrate in Dart or Flutter apps.

> Important: This package was authored as an experiment to see how far AI‑assisted engineering can go in a real-world library. The codebase, docs, tests, and design decisions were developed with heavy AI assistance and careful human review.

## Repository Guidelines

See [AGENTS.md](AGENTS.md) for contributor and development guidelines, and [CONTRIBUTING.md](CONTRIBUTING.md) for workflow rules (verify script, commit format, examples, hooks).

## Features

- Strongly-typed Xtream Codes client with clear, consistent errors
- Pluggable HTTP adapter with timeouts, retries, redirects, TLS options
- Cooperative cancellation support across requests and parsing
- URL builders for live, VOD, and series (HLS first with TS fallback)
- EPG helpers including short-EPG and channel-id fallbacks
- M3U and XMLTV helpers for quick ingestion and parsing
- Redaction-first logging to prevent leaking secrets

## Getting started

- Install Dart SDK and run `dart pub get` in the repo.
- Try the example app to exercise the public API as it evolves.
  - `dart run example/main.dart --portal https://your.portal/ --user USER --pass PASS`
  - The example is updated with every new API addition so you can quickly verify behavior end-to-end.

## Usage

- See `example/main.dart` for live usage of the APIs, including:
  - `XtreamClient.getUserAndServerInfo()`
  - Catalogs: `getLiveCategories`, `getVodCategories`, `getSeriesCategories`, and corresponding list fetchers
  - Details: `getVodInfo`, `getSeriesInfo`
  - EPG: `getShortEpg(streamId, limit)`
    - Note: some portals serve EPG only by `epg_channel_id` (not by `stream_id`).
      The client API also accepts `epgChannelId` and, when both are provided, retries internally if the `stream_id` query returns empty.
  - Diagnostics: `ping()` and `capabilities()`
  - URL builders: `liveUrl`, `vodUrl`, `seriesUrl`
  - Probe helper: `suggestStreamExtension`

### Create a client

```dart
import 'package:muxa_xtream/muxa_xtream.dart';

final portal = XtreamPortal.parse('https://your-portal.example:8080');
final credentials = XtreamCredentials(username: 'USER', password: 'PASS');

// Optional: pass a custom HTTP adapter or options
final client = XtreamClient(
  portal,
  credentials,
  // http: createDefaultHttpAdapter(),
  // options: const XtreamClientOptions(receiveTimeout: Duration(seconds: 20)),
);
```

### Account/server info

```dart
final info = await client.getUserAndServerInfo();
print('User: ${info.user.username}, server: ${info.server.serverName}');
```

### Catalogs

```dart
final liveCats = await client.getLiveCategories();
final vodCats = await client.getVodCategories();
final seriesCats = await client.getSeriesCategories();

final live = await client.getLiveStreams(categoryId: liveCats.first.id);
final vod = await client.getVodStreams(categoryId: vodCats.first.id);
final series = await client.getSeries(categoryId: seriesCats.first.id);
```

### Details

```dart
final vodDetails = await client.getVodInfo(vod.first.streamId);
final seriesDetails = await client.getSeriesInfo(series.first.seriesId);
```

### EPG (short)

```dart
// Prefer epgChannelId when known; otherwise use streamId
final epg = await client.getShortEpg(streamId: live.first.streamId, limit: 5);
```

### URL builders (no network I/O)

```dart
final liveHls = liveUrl(portal, credentials, live.first.streamId);
final vodHls = vodUrl(portal, credentials, vod.first.streamId);
final seriesHls = seriesUrl(portal, credentials, series.first.seriesId);
```

### Diagnostics

```dart
final health = await client.ping();
final caps = await client.capabilities();
print('Ping ok=${health.ok} ${health.latency} caps: m3u=${caps.supportsM3u}');
```

### Optional: M3U and XMLTV

```dart
// M3U entries (first 10)
await for (final entry in client.getM3u().take(10)) {
  print('M3U: ${entry.name} -> ${entry.url}');
}

// XMLTV: channels and programmes stream in a single sequence
await for (final ev in client.getXmltv()) {
  // ev is XtXmltvChannel or XtXmltvProgramme
}
```

## Quick start

Use the Xtream Codes client to query account info, catalogs, details, EPG, and build streaming URLs.

```dart
import 'package:muxa_xtream/muxa_xtream.dart';

Future<void> main() async {
  final portal = XtreamPortal.parse('https://your-portal.example:8080');
  final credentials = XtreamCredentials(username: 'username', password: 'password');

  final client = XtreamClient(portal, credentials);

  // Basic health
  final health = await client.ping();
  print('Ping: ${health.latency.inMilliseconds}ms');

  // Account and server
  final info = await client.getUserAndServerInfo();
  print('User: ${info.user.username} @ ${info.server.serverName}');

  // Catalogs
  final liveCats = await client.getLiveCategories();
  final live = await client.getLiveStreams(categoryId: liveCats.first.id);
  print('First live channel: ${live.first.name}');

  // URL builders (no I/O)
  final hlsUrl = liveUrl(portal, credentials, live.first.streamId);
  print('HLS URL: $hlsUrl');
}
```

> Tip: prefer environment variables or a local-only config file for credentials. Avoid hard-coding secrets.

## Examples

- See `example/main.dart` for a runnable demo that exercises the public API.
- The example prints basic diagnostics and demonstrates catalogs, details, EPG, and URL builders.

## Capability notes

- Transport: pluggable HTTP adapter with timeouts, retries, redirects, TLS options, and header injection.
- Errors: consistent taxonomy (auth/network/parse/blocked/unsupported) with redaction to avoid leaking secrets.
- Models & parsing: tolerant JSON parsing with UTC normalization.
- URL builders: `liveUrl`, `vodUrl`, `seriesUrl` default to HLS with TS fallback; probing helper available.
- M3U & XMLTV: optional helpers for `get.php` and streaming XMLTV parse with cancellation.
- Reliability: cancellation and timeouts propagate end-to-end.

## Troubleshooting

- If a call fails with an HTML response, the portal may be blocked or behind a captive page; check `XtPortalBlockedError`.
- For 401/403, verify credentials and IP whitelist.
- For timeouts, increase `requestTimeout` in `XtreamClientOptions` or check connectivity.

## Security

- Never commit credentials.
- Logs are redacted by default; avoid logging raw responses that may contain secrets.
- See `AGENTS.md` for repository and contribution guidelines.

## Additional information

- Documentation: see the `doc/` folder for API notes, design, and integration guidance.
- Example: run `dart run example/main.dart` to try common flows end-to-end.
- Issues and contributions: please read `AGENTS.md` and `CONTRIBUTING.md`, then open issues/PRs with clear repro steps and expected behavior.
- Security: never include credentials in issues; redact sensitive URLs or logs.
