 # muxa_xtream — Public API Reference (self-contained)

 This document describes the public API surface of the `muxa_xtream` package in a self-contained way so other agents can call the library without reading the source.

 Import

 - Single import that exposes the public API:

 ```dart
 import 'package:muxa_xtream/muxa_xtream.dart';
 ```

 Top-level exports (what you get from the import)

 - High-level client: `XtreamClient`
 - Models and DTOs: user, server, category, live, vod, series, epg, capabilities, health, m3u, xmltv
 - Errors: `XtError` and concrete subclasses
 - HTTP adapter interfaces: `XtHttpAdapter`, `XtRequest`, `XtResponse`
 - Cancellation helper: `XtCancellationToken`
 - Utilities: URL builders, logging, redaction
 - Package version string: `muxaXtreamVersion`

 High-level contract (types & signatures)

 - Constructor

 ```dart
 XtreamClient(
   XtreamPortal portal,
   XtreamCredentials creds, {
   XtreamClientOptions? options,
   XtHttpAdapter? http,
   XtreamLogger? logger,
 })
 ```

 - Main asynchronous methods (exact signatures):

 ```dart
 Future<XtUserAndServerInfo> getUserAndServerInfo({XtCancellationToken? cancel});

 Future<List<XtCategory>> getLiveCategories({XtCancellationToken? cancel});
 Future<List<XtCategory>> getVodCategories({XtCancellationToken? cancel});
 Future<List<XtCategory>> getSeriesCategories({XtCancellationToken? cancel});

 Future<List<XtLiveChannel>> getLiveStreams({String? categoryId, XtCancellationToken? cancel});
 Future<List<XtVodItem>> getVodStreams({String? categoryId, XtCancellationToken? cancel});
 Future<List<XtSeriesItem>> getSeries({String? categoryId, XtCancellationToken? cancel});

 Future<XtVodDetails> getVodInfo(int vodId, {XtCancellationToken? cancel});
 Future<XtSeriesDetails> getSeriesInfo(int seriesId, {XtCancellationToken? cancel});

 Future<List<XtEpgEntry>> getShortEpg({int? streamId, String? epgChannelId, int limit = 10, XtCancellationToken? cancel});

 Future<XtHealth> ping({XtCancellationToken? cancel});
 Future<XtCapabilities> capabilities();

 Stream<XtM3uEntry> getM3u({String output = 'hls', XtCancellationToken? cancel});
 Stream<XtXmltvEvent> getXmltv({XtCancellationToken? cancel});
 ```

 Error model (exceptions)

 - XtError (base)
 - XtAuthError — authentication failure (HTTP 401 / 403)
 - XtNetworkError — HTTP/network errors
 - XtParseError — invalid/unexpected response data
 - XtUnsupportedError — client misuse or missing required params
 - XtPortalBlockedError — portal blocked (HTTP 451)

 Behavioural notes

 - Methods return plain Dart futures/streams. They throw the errors above on failure.
 - `getM3u` and `getXmltv` are optional: servers may not implement those endpoints.
 - `getShortEpg` accepts either `streamId` (numeric) or `epgChannelId` (string) — provide at least one.
 - `capabilities()` attempts to discover server features and returns sensible defaults if the server doesn't expose the capability endpoint.

 Common models and typical JSON shapes

 The client parses server JSON into typed model objects. Servers (Xtream-style) are inconsistent; the examples here show typical fields other agents can expect. Field presence and names may vary by portal.

 XtUserAndServerInfo

 - Returned by `getUserAndServerInfo()`
 - Typical structure:

 ```json
 {
   "user_info": {
     "username": "alice",
     "status": "Active",
     "is_premium": true,
     "created_at": "2024-01-01"
   },
   "server_info": {
     "name": "Example Xtream",
     "version": "2.0",
     "base_url": "https://my-xtream.example"
   }
 }
 ```

 XtCategory

 - Typical item returned by category endpoints:

 ```json
 {
   "category_id": "10",
   "category_name": "Sports",
   "parent_id": "0"
 }
 ```

 XtLiveChannel (typical entry from `get_live_streams`)

 ```json
 {
   "stream_id": 12345,
   "name": "Example Channel",
   "stream_icon": "https://.../logo.png",
   "num": "101",
   "epg_channel_id": "example.channel",
   "stream_type": "live",
   "container_extension": "m3u8",
   "stream_url": "http://.../playlist.m3u8"
 }
 ```

 XtVodItem (typical `get_vod_streams` item)

 ```json
 {
   "vod_id": 9876,
   "title": "Example Movie",
   "description": "A short description",
   "rating": "7.2",
   "genre": "Drama",
   "stream_icon": "https://.../cover.jpg"
 }
 ```

 XtVodDetails (detailed VOD info)

 ```json
 {
   "vod_id": 9876,
   "title": "Example Movie",
   "plot": "Full synopsis...",
   "duration": 7200,
   "streams": [
     { "url": "...", "container": "mp4" }
   ]
 }
 ```

 XtSeriesItem and XtSeriesDetails

 - Series items generally include `series_id`, `title`, and an optional `cover`.
 - Details include seasons/episodes arrays.

 XtEpgEntry (short EPG)

 ```json
 {
   "title": "News",
   "start": "20250819T180000Z",
   "stop": "20250819T183000Z",
   "description": "Evening news",
   "channel": "example.channel"
 }
 ```

 XtCapabilities (discovery)

 - Example normalized output (package converts server results into a typed object):

 ```json
 {
   "supports_m3u": true,
   "supports_xmltv": false,
   "supports_short_epg": true
 }
 ```

 XtHealth (ping result)

 - Fields returned by `ping()`:
 ```json
 {
   "ok": true,
   "statusCode": 200,
   "latencyMs": 123
 }
 ```

 XtM3uEntry (streamed from `getM3u` parser)

 ```json
 {
   "tvg-id": "example.channel",
   "tvg-name": "Example Channel",
   "group-title": "News",
   "uri": "http://.../stream.m3u8"
 }
 ```

 XtXmltvEvent (streamed from `getXmltv` parser)

 ```json
 {
   "channel": "example.channel",
   "programme": {
     "title": "Show name",
     "start": "20250819T180000Z",
     "stop": "20250819T183000Z",
     "desc": "Episode description"
   }
 }
 ```

 HTTP adapter contract (summary)

 - The client uses an adapter abstraction with the following minimal contract:
   - `XtRequest` includes: `url` (Uri), `headers` (Map<String,String>), optional `timeout`, optional `cancel` token.
   # muxa_xtream — Client-facing API Reference

   Purpose

   This document is targeted at *clients* of the `muxa_xtream` Dart package. It explains every public method, parameter, return type, thrown errors, and every public model (each field's Dart type and intent). It intentionally omits parsing/JSON schema details — it tells you how to call and consume the package.

   Import

   ```dart
   import 'package:muxa_xtream/muxa_xtream.dart';
   ```

   Quick exports you get from the import

   - `XtreamClient` — main client
   - URL builders: `liveUrl`, `vodUrl`, `seriesUrl`
   - Models: `XtreamPortal`, `XtreamCredentials`, `XtCategory`, `XtLiveChannel`, `XtVodItem`, `XtVodDetails`, `XtSeriesItem`, `XtSeriesDetails`, `XtEpisode`, `XtEpgEntry`, `XtCapabilities`, `XtHealth`, `XtM3uEntry`, `XtXmltvChannel`, `XtXmltvProgramme`, `XtUserInfo`, `XtServerInfo`, `XtUserAndServerInfo`
   - Errors: `XtError` and concrete subclasses (`XtAuthError`, `XtNetworkError`, `XtParseError`, `XtUnsupportedError`, `XtPortalBlockedError`)
   - `XtCancellationToken`, `XtHttpAdapter` (adapter contract) and `muxaXtreamVersion`

   --------------------------------------------------
   Methods (detailed)
   --------------------------------------------------

   All methods are instance methods on `XtreamClient` unless noted otherwise. The signatures below are exact; the descriptions list parameters, return type, thrown errors and notes.

   1) XtreamClient constructor

   ```dart
   XtreamClient(
     XtreamPortal portal,
     XtreamCredentials creds, {
     XtreamClientOptions? options,
     XtHttpAdapter? http,
     XtreamLogger? logger,
   })
   ```
   - portal: `XtreamPortal` — portal base URI and normalization helper.
   - creds: `XtreamCredentials` — username/password pair.
   - options: `XtreamClientOptions?` — optional client timeouts / headers / user agent.
   - http: `XtHttpAdapter?` — optional custom HTTP adapter; defaults to platform adapter.
   - logger: `XtreamLogger?` — optional logger.

   2) Future<XtUserAndServerInfo> getUserAndServerInfo({XtCancellationToken? cancel})
   - Params: optional `cancel` token to abort the request.
   - Returns: `XtUserAndServerInfo` (contains `XtUserInfo` and `XtServerInfo`).
   - Throws: `XtAuthError` (401/403), `XtNetworkError`, `XtParseError` on invalid JSON.
   - Notes: Calls `player_api.php` and validates presence of `user_info` and `server_info`.

   3) Future<List<XtCategory>> getLiveCategories({XtCancellationToken? cancel})
   4) Future<List<XtCategory>> getVodCategories({XtCancellationToken? cancel})
   5) Future<List<XtCategory>> getSeriesCategories({XtCancellationToken? cancel})
   - Params: optional `cancel`.
   - Returns: list of `XtCategory` (id, name, kind).
   - Throws: `XtNetworkError`, `XtParseError`.
   - Notes: Use the appropriate method for the type of catalog you need.

   6) Future<List<XtLiveChannel>> getLiveStreams({String? categoryId, XtCancellationToken? cancel})
   - Params: `categoryId` optional filter (string), optional `cancel`.
   - Returns: `List<XtLiveChannel>`.
   - Throws: `XtNetworkError`, `XtParseError`.
   - Notes: Category filtering is server-dependent.

   7) Future<List<XtVodItem>> getVodStreams({String? categoryId, XtCancellationToken? cancel})
   8) Future<List<XtSeriesItem>> getSeries({String? categoryId, XtCancellationToken? cancel})
   - Same param/return/throws contract as `getLiveStreams` but for VOD or series.

   9) Future<XtVodDetails> getVodInfo(int vodId, {XtCancellationToken? cancel})
   - Params: `vodId` (int) — required; optional `cancel`.
   - Returns: `XtVodDetails`.
   - Throws: `XtNetworkError`, `XtParseError`.

   10) Future<XtSeriesDetails> getSeriesInfo(int seriesId, {XtCancellationToken? cancel})
   - Params: `seriesId` (int) — required; optional `cancel`.
   - Returns: `XtSeriesDetails`.
   - Throws: `XtNetworkError`, `XtParseError`.

   11) Future<List<XtEpgEntry>> getShortEpg({int? streamId, String? epgChannelId, int limit = 10, XtCancellationToken? cancel})
   - Params:
     - `streamId` (int?) — stream numeric id (optional)
     - `epgChannelId` (String?) — portal EPG channel id (optional)
     - `limit` (int) — maximum entries (default 10)
     - `cancel` — optional cancel token
   - Returns: `List<XtEpgEntry>` (may be empty if no EPG available)
   - Throws: `XtUnsupportedError` if neither `streamId` nor `epgChannelId` provided; `XtNetworkError`, `XtParseError`.
   - Notes: Some portals respond only to `epg_channel_id` — client will attempt a retry with `epgChannelId` when both are provided and the first result is empty.

   12) Future<XtHealth> ping({XtCancellationToken? cancel})
   - Params: optional `cancel`.
   - Returns: `XtHealth` (ok, statusCode, latency).
   - Throws: `XtNetworkError` on HTTP failure.
   - Notes: Lightweight check that calls `player_api.php` and measures latency.

   13) Future<XtCapabilities> capabilities()
   - Params: none.
   - Returns: `XtCapabilities` (supportsShortEpg, supportsM3u, supportsXmltv, ...)
   - Throws: `XtNetworkError` or `XtAuthError`; otherwise returns sensible defaults when parsing fails.

   14) Stream<XtM3uEntry> getM3u({String output = 'hls', XtCancellationToken? cancel})
   - Params: `output` controls preferred extension (`'hls'` → `.m3u8` or `'ts'`), optional `cancel`.
   - Returns: Stream of `XtM3uEntry` parsed from playlist.
   - Throws: `XtNetworkError` if endpoint missing or returns error. Treat as optional feature.

   15) Stream<XtXmltvEvent> getXmltv({XtCancellationToken? cancel})
   - Params: optional `cancel`.
   - Returns: Stream of `XtXmltvEvent` (either `XtXmltvChannel` or `XtXmltvProgramme`).
   - Throws: `XtNetworkError` if endpoint missing. Treat as optional feature.

   --------------------------------------------------
   Models (fields, Dart types, and purpose)
   --------------------------------------------------

   Each model below lists the Dart field name, its type, and a one-line purpose. All fields are public final members on the model class.

   XtreamPortal
   - `Uri baseUri` — portal base URL (normalized); use `XtreamPortal.parse(String)` to construct from a string.

   XtreamCredentials
   - `String username` — plain username
   - `String password` — plain password
   - `String maskedUsername` — redacted username for logs
   - `String maskedPassword` — redacted password for logs

   XtreamClientOptions
   - `Duration connectTimeout` — connect timeout
   - `Duration receiveTimeout` — per-request receive timeout
   - `String? userAgent` — optional User-Agent header
   - `Map<String,String> defaultHeaders` — headers added to every request

   XtUserInfo
   - `String username` — account username
   - `bool active` — whether account is active
   - `DateTime? expiresAt` — optional account expiry timestamp (UTC)
   - `int? maxConnections` — allowed concurrent streams (if provided)
   - `bool? trial` — whether the account is marked as a trial

   XtServerInfo
   - `Uri baseUrl` — server URL as returned by portal
   - `String? serverName` — human-readable server name
   - `String? timezone` — server timezone if provided
   - `bool? https` — whether server indicates HTTPS usage

   XtUserAndServerInfo
   - `XtUserInfo user` — user/account information
   - `XtServerInfo server` — server information

   XtCategory
   - `String id` — category identifier (string)
   - `String name` — human-readable category name
   - `String kind` — one of `'live'`, `'vod'`, `'series'` to indicate catalog type

   XtLiveChannel
   - `int streamId` — numeric stream identifier (use to build playable URLs)
   - `String name` — channel name / title
   - `String categoryId` — category id this channel belongs to
   - `String? logoUrl` — optional URL for channel icon/logo
   - `String? epgChannelId` — optional EPG channel id used by some portals

   XtVodItem
   - `int streamId` — numeric VOD id
   - `String name` — title/name of the movie/item
   - `String categoryId` — category id
   - `String? posterUrl` — URL for poster/cover image

   XtVodDetails
   - `int streamId` — VOD id
   - `String name` — title
   - `String? plot` — synopsis / description
   - `double? rating` — numeric rating if present
   - `int? year` — production/release year
   - `Duration? duration` — runtime
   - `String? posterUrl` — artwork URL

   XtSeriesItem
   - `int seriesId` — series identifier
   - `String name` — series title
   - `String categoryId` — category id
   - `String? posterUrl` — artwork URL

   XtEpisode
   - `int id` — episode stream id (useable with seriesUrl builder)
   - `String title` — episode title
   - `int season` — season number
   - `int episode` — episode number
   - `Duration? duration` — runtime
   - `String? plot` — episode description

   XtSeriesDetails
   - `int seriesId` — series id
   - `String name` — series title
   - `String? plot` — series synopsis
   - `Map<int, List<XtEpisode>> seasons` — mapping seasonNumber → episodes
   - `String? posterUrl` — artwork URL

   XtEpgEntry
   - `String channelId` — provider channel id used for EPG lookups
   - `DateTime startUtc` — programme start time (UTC)
   - `DateTime endUtc` — programme end time (UTC)
   - `String title` — programme title
   - `String? description` — optional programme description

   XtCapabilities
   - `bool supportsShortEpg` — short EPG endpoint support
   - `bool supportsExtendedEpg` — extended EPG support
   - `bool supportsM3u` — M3U playlist support
   - `bool supportsXmltv` — XMLTV EPG support

   XtHealth
   - `bool ok` — whether the ping returned a successful response
   - `int statusCode` — HTTP status code
   - `Duration latency` — measured RTT for the ping

   XtM3uEntry
   - `String url` — stream URI
   - `String name` — human name/title
   - `String? tvgId` — tvg-id if present
   - `String? groupTitle` — group-title if present
   - `String? logoUrl` — logo URL
   - `Map<String,String> attrs` — raw attributes parsed from the EXTINF line

   XtXmltvChannel
   - `String id` — XMLTV channel id
   - `String? displayName` — display name
   - `String? iconUrl` — icon URL

   XtXmltvProgramme
   - `String channelId` — channel id the programme belongs to
   - `DateTime start` — programme start time
   - `DateTime? stop` — programme end time
   - `String? title` — programme title
   - `String? description` — programme description
   - `List<String> categories` — categories/genres

   --------------------------------------------------
   URL builders (how to build playable URLs)
   --------------------------------------------------

   The package exposes top-level functions for building direct playable URIs. These are not methods on the client; call them with `client.portal` and `client.creds` when you have a client instance.

   - `Uri liveUrl(XtreamPortal portal, XtreamCredentials creds, int streamId, {String extension = 'm3u8'})`
     - Builds a URI like: <base>/<...>/live/<username>/<password>/<streamId>.<extension>

   - `Uri vodUrl(XtreamPortal portal, XtreamCredentials creds, int streamId, {String extension = 'm3u8'})`
     - Builds a URI like: <base>/<...>/movie/<username>/<password>/<streamId>.<extension>

   - `Uri seriesUrl(XtreamPortal portal, XtreamCredentials creds, int episodeId, {String extension = 'm3u8'})`
     - Builds a URI like: <base>/<...>/series/<username>/<password>/<episodeId>.<extension>

   Example

   ```dart
   final client = XtreamClient(XtreamPortal.parse('https://my-xtream.example'), XtreamCredentials(username: 'alice', password: 'hunter2'));
   final channels = await client.getLiveStreams();
   if (channels.isNotEmpty) {
     final uri = liveUrl(client.portal, client.creds, channels.first.streamId);
     // uri -> .../<streamId>.m3u8
   }
   ```

   --------------------------------------------------
   Errors and best practices
   --------------------------------------------------

   - Catch `XtAuthError` for credential problems and `XtNetworkError` for transient network issues.
   - Treat `getM3u` and `getXmltv` as optional — validate with `capabilities()` before relying on them.
   - Use `XtCancellationToken` for long-running stream operations.
   - Always validate nullable fields (many model fields are optional) and treat empty strings or zeros as "absent" values from portals.

   Completion

   This reference now contains every public method (parameters, returns, thrown errors) and each public model with exact Dart field names, types, and purpose so clients can integrate with `muxa_xtream` without reading the source code.
