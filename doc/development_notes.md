# muxa_stream — Feature Requirements

A practical, implementation‑ready specification for a **Dart** package that talks to Xtream/XUI servers and plugs into Flutter apps like **Muxa**.

---

## 1) Purpose & Scope

A small, safe, and typed **Xtream API client** for Dart/Flutter:

- Discover & validate portals
- Authenticate and fetch account/server info
- List catalogs (live, VOD, series) and categories
- Fetch details (VOD/series/EPG)
- Build playable URLs for live/VOD/series
- Optional: M3U and XMLTV ingestion with streaming/isolated parsing

**Out of scope (v1):** player UI, DRM, transcoding, local DB. Hooks will be provided so the app can store/cache as desired.

---

## 2) Platforms & Runtime

- Dart ≥ 3.x, null‑safe
- Flutter: Android, iOS, macOS, Windows, Linux, Web*
- Dart VM/CLI supported
- Works with `http` and `dart:io`/`dart:html` (conditional imports)

> \* Web caveats: CORS and mixed‑content restrictions apply; expose a pluggable transport so apps can proxy through their own backend when required.

---

## 3) Security & Privacy

- **Credential redaction:** Never log `username`/`password`. Redact them in URLs, headers, and error messages.
- **TLS:** Enabled by default. Allow custom `HttpClient`/`SecurityContext`. Optional `allowSelfSigned` flag (off by default).
- **Timeouts:** Configurable connect/read timeouts; defaults: connect **10s**, read **30s**.
- **Retries:** Exponential backoff with jitter for idempotent GETs only. Defaults: max **3** attempts, base delay **400ms**.
- **Transport hooks:** Allow custom headers, user‑agent, and token/nonce injection for future auth variants.
- **Data minimization:** Models keep only necessary fields; the package never persists data by itself.
- **PII boundaries:** No implicit analytics. Logging is opt‑in via a redacting logger interface.

**Redaction rule (example):**  
`https://host/player_api.php?username=john&password=secret` → `https://host/player_api.php?username=***&password=***`

---

## 4) Public API Surface

### 4.1 Core Types

```dart
class XtreamPortal {
  final Uri baseUrl; // e.g., http://host:port/
  const XtreamPortal(this.baseUrl);
}

class XtreamCredentials {
  final String username;
  final String password;
  const XtreamCredentials(this.username, this.password);
}

class XtreamClientOptions {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetries;
  final Duration retryBaseDelay;
  final Map<String, String> defaultHeaders;
  final bool followRedirects;
  final bool allowSelfSigned; // default: false
  const XtreamClientOptions({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryBaseDelay = const Duration(milliseconds: 400),
    this.defaultHeaders = const {},
    this.followRedirects = true,
    this.allowSelfSigned = false,
  });
}
```

### 4.2 Client

```dart
abstract class XtreamClient {
  factory XtreamClient(
    XtreamPortal portal,
    XtreamCredentials creds, {
    XtreamClientOptions options,
    XtreamHttpAdapter? http, // injectable transport
    XtreamLogger? logger,    // redacting logger
  }) = XtreamClientImpl;

  // Account & server info
  Future<XtUserAndServerInfo> getUserAndServerInfo();

  // Live
  Future<List<XtCategory>> getLiveCategories();
  Future<List<XtLiveStream>> getLiveStreams({String? categoryId});

  // VOD
  Future<List<XtCategory>> getVodCategories();
  Future<List<XtVodStream>> getVodStreams({String? categoryId});
  Future<XtVodDetails> getVodInfo(int vodId);

  // Series
  Future<List<XtCategory>> getSeriesCategories();
  Future<List<XtSeries>> getSeries({String? categoryId});
  Future<XtSeriesDetails> getSeriesInfo(int seriesId);

  // EPG
  Future<List<XtEpgEntry>> getShortEpg({required int streamId, int limit = 10});

  // URL builders (no network I/O)
  Uri liveUrl(int streamId, {XtStreamFormat format = XtStreamFormat.hls});
  Uri vodUrl(int streamId, {String? ext});
  Uri seriesUrl(int episodeStreamId, {String? ext});

  // Optional features
  Future<XtM3uPlaylist> fetchM3u({XtM3uOptions? options});
  Stream<XtXmltvEvent> streamXmltv({XtXmltvOptions? options});

  // Diagnostics
  Future<XtHealth> ping();
  Future<XtCapabilities> capabilities();
}
```

### 4.3 Detection Helpers

```dart
class XtDetect {
  /// Identify whether a given URL looks like an Xtream portal,
  /// a playlist export (get.php), or an XMLTV endpoint.
  static Future<XtDetectionResult> detect(Uri url);
}
```

### 4.4 Models (selection, stable for v1)

```dart
class XtUserAndServerInfo {
  final XtUserInfo user;
  final XtServerInfo server;
  const XtUserAndServerInfo(this.user, this.server);
}

class XtUserInfo {
  final String status;         // 'Active', etc.
  final DateTime? trialUntil;  // nullable
  final DateTime? expiresAt;   // nullable
  final int? maxConnections;
  const XtUserInfo({required this.status, this.trialUntil, this.expiresAt, this.maxConnections});
}

class XtServerInfo {
  final Uri baseUrl;           // normalized
  final String? serverProtocol; // http/https
  final int? port;
  final String apiVersion;     // best effort
  const XtServerInfo({required this.baseUrl, this.serverProtocol, this.port, this.apiVersion = 'unknown'});
}

class XtCategory {
  final String categoryId;
  final String name;
  const XtCategory(this.categoryId, this.name);
}

class XtLiveStream {
  final int streamId;
  final String name;
  final String? logo;
  final String? epgChannelId;
  final String? categoryId;
  final bool? hasCatchup;
  const XtLiveStream({required this.streamId, required this.name, this.logo, this.epgChannelId, this.categoryId, this.hasCatchup});
}

class XtVodStream {
  final int streamId;
  final String title;
  final String? poster;
  final String? categoryId;
  const XtVodStream({required this.streamId, required this.title, this.poster, this.categoryId});
}

class XtSeries {
  final int seriesId;
  final String title;
  final String? poster;
  final String? categoryId;
  const XtSeries({required this.seriesId, required this.title, this.poster, this.categoryId});
}

class XtVodDetails {
  final int streamId;
  final String? plot;
  final List<String>? genres;
  final String? released; // YYYY-MM-DD if present
  final String? rating;   // e.g., IMDb string
  final List<String>? backdrops;
  final XtFileInfo? file;
  const XtVodDetails({required this.streamId, this.plot, this.genres, this.released, this.rating, this.backdrops, this.file});
}

class XtFileInfo {
  final String? container; // mp4/mkv/ts
  final int? sizeBytes;
  final Duration? duration;
  const XtFileInfo({this.container, this.sizeBytes, this.duration});
}

class XtSeriesDetails {
  final int seriesId;
  final List<XtSeason> seasons;
  const XtSeriesDetails({required this.seriesId, required this.seasons});
}

class XtSeason {
  final int number;
  final List<XtEpisode> episodes;
  const XtSeason({required this.number, required this.episodes});
}

class XtEpisode {
  final int streamId; // episode stream id
  final int season;
  final int episode;
  final String title;
  final String? overview;
  final String? poster;
  final Duration? duration;
  const XtEpisode({required this.streamId, required this.season, required this.episode, required this.title, this.overview, this.poster, this.duration});
}

class XtEpgEntry {
  final String title;
  final DateTime start;
  final DateTime end;
  final String? desc;
  const XtEpgEntry({required this.title, required this.start, required this.end, this.desc});
}

enum XtStreamFormat { hls, ts }
```

### 4.5 Errors & Result Handling

```dart
sealed class XtError implements Exception {
  final String message;
  final int? statusCode;
  const XtError(this.message, {this.statusCode});
}

class XtAuthError extends XtError {
  const XtAuthError(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class XtNetworkError extends XtError {
  final bool timedOut;
  const XtNetworkError(String message, {this.timedOut = false, int? statusCode}) : super(message, statusCode: statusCode);
}

class XtParseError extends XtError {
  const XtParseError(String message) : super(message);
}

class XtPortalBlockedError extends XtError {
  const XtPortalBlockedError(String message, {int? statusCode}) : super(message, statusCode: statusCode);
}

class XtUnsupportedError extends XtError {
  const XtUnsupportedError(String message) : super(message);
}
```
- All public methods throw `XtError` subclasses. No `null` on success paths.
- Optionally provide `XtEither<T>` wrappers for functional style without exceptions (can be added in a minor version).

### 4.6 Logging

```dart
abstract class XtreamLogger {
  void debug(String msg); // credentials must be redacted
  void warn(String msg);
  void error(String msg, [Object? err, StackTrace? st]);
}
```

---

## 5) Networking Details

- **Transport abstraction** (`XtreamHttpAdapter`) so apps can plug in `package:http`, `dio`, or a mock.
- Default adapter:
  - Adds timeouts & retries (GET only), exponential backoff with jitter.
  - Redacts credentials in all URL strings.
  - Follows redirects (configurable).
- **JSON** via `dart:convert` with robust null/field guards.
- **Large responses:** stream and decode in chunks; avoid holding giant arrays unnecessarily.
- **User‑Agent override:** optional; some portals behave differently.

---

## 6) Endpoints (v1 Coverage)

- `player_api.php`
  - `GET ?username&password` → user/server info
  - `action=get_live_categories|get_live_streams`
  - `action=get_vod_categories|get_vod_streams|get_vod_info&vod_id=`
  - `action=get_series_categories|get_series|get_series_info&series_id=`
  - `action=get_short_epg&stream_id=&limit=`

- `get.php` (optional): M3U export (`type=m3u_plus`, `output=ts|hls`)
- `xmltv.php` (optional): XMLTV feed (large; see EPG strategy)

> Forks differ slightly; treat fields as **loosely typed** and add best‑effort parsing with safe defaults.

---

## 7) URL Builders (No I/O)

- **Live:** `/live/<user>/<pass>/<streamId>.(m3u8|ts)` (default to HLS; fallback to TS if needed)
- **VOD:** `/movie/<user>/<pass>/<streamId>.<ext>`
- **Series:** `/series/<user>/<pass>/<episodeStreamId>.<ext>`

**Extension inference:** if unknown, try a HEAD probe; fallback to GET with `Range: bytes=0-0` and detect by `Content-Type` or redirects.

---

## 8) EPG Strategy

- **Short EPG:** `get_short_epg` for now/next and small windows.
- **XMLTV (optional):** stream‑parse on a background **isolate** using a SAX‑style parser:
  - Emits `XtXmltvEvent` items (`channel`, `programme` start/end, metadata).
  - Backpressure via `StreamController`.
  - Cancellation support for early exit.
- Normalize all times to **UTC** in models; provide helpers to convert to local timezones at the UI layer.

---

## 9) Performance & Memory

- Lazy mapping and optional streamed iteration for very large catalogs.
- Prefer `List` returns by default for ergonomics; offer streaming APIs where it matters.
- XMLTV: O(1) incremental parsing; never build a full DOM tree.

---

## 10) Config & Feature Flags

- `XtFeatures(epgXmltv: true/false, m3u: true/false, allowSelfSigned: false)`
- Tree‑shake friendly: isolate XMLTV parser into a separate import to avoid pulling it when unused.

---

## 11) Testing Strategy

- **Unit tests:** model parsing (golden JSON samples), URL builders, redaction, retry/backoff logic.
- **Contract tests:** hit a local mock server (recorded fixtures) to validate endpoints and error taxonomy.
- **Robustness:** malformed/missing fields, HTML error pages instead of JSON, 401/403, 429 throttling.
- **CI:** run on Dart/Flutter stable; aim for **≥ 90%** coverage for core modules.

---

## 12) Example Usage

```dart
final client = XtreamClient(
  XtreamPortal(Uri.parse('https://portal.example.com/')),
  XtreamCredentials('user', 'pass'),
);

final info = await client.getUserAndServerInfo();

final categories = await client.getLiveCategories();
final sportsCat = categories.firstWhere(
  (c) => c.name.toLowerCase().contains('sport'),
  orElse: () => categories.first,
);

final live = await client.getLiveStreams(categoryId: sportsCat.categoryId);

// Build a playable URL:
final hlsUrl = client.liveUrl(live.first.streamId); // .m3u8 default

// Short EPG (now/next):
final epg = await client.getShortEpg(streamId: live.first.streamId, limit: 5);
```

---

## 13) Documentation

- README with quick start and the example above.
- API docs (dartdoc) with endpoint notes and field caveats.
- **Security & logging** section (redaction examples).
- **Handling huge lists** section (streaming APIs and isolates).

---

## 14) Versioning & Compatibility

- **SemVer**.
- **v1.0.0**: endpoints above + optional M3U/XMLTV.
- `capabilities()` exposes detected panel quirks (e.g., missing actions or blocked XMLTV).

---

## 15) Licensing & Compliance

- MIT license.
- This is a client library; no affiliation with any provider. Users are responsible for legality and content rights.

---

## 16) Roadmap (Post‑v1)

- Catch‑up/Timeshift support (`/timeshift/...`) when exposed by portals.
- Per‑stream header & user‑agent overrides.
- Built‑in lightweight cache interface (user‑supplied storage).
- Rate‑limit detection (429) with adaptive backoff.
- Portal discovery via MAC/Stalker (optional separate module).

---

## 17) Project Layout Recommendation (informative, non‑binding)

```
muxa_stream/
  lib/
    muxa_stream.dart          // export surface
    src/
      client.dart             // XtreamClient interface + impl
      http_adapter.dart       // transport abstraction + default adapter
      logger.dart             // redacting logger
      models/                 // entities
      parsing/                // json/xml parsing
      url_builders.dart
      features.dart           // feature flags/capabilities
  test/
    unit/                     // parsing, url, redaction, backoff
    contract/                 // mock server fixtures
  LICENSE
  README.md
```
