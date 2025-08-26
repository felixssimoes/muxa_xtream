import 'dart:convert';
import 'dart:async';

import 'core/errors.dart';
import 'core/logger.dart';
import 'core/models.dart';
import 'core/redaction.dart';
import 'http/adapter.dart';
import 'http/adapter_factory.dart';
import 'core/cancellation.dart';
import 'models/account.dart';
import 'models/category.dart';
import 'models/live.dart';
import 'models/vod.dart';
import 'models/series.dart';
import 'models/epg.dart';
import 'models/capabilities.dart';
import 'models/health.dart';
import 'models/server.dart';
import 'models/user.dart';
import 'm3u/parser.dart';
import 'models/m3u.dart';
import 'models/xmltv.dart';
import 'xmltv/parser.dart';

/// High-level Xtream client for account, catalogs, details, diagnostics, and helpers.
class XtreamClient {
  final XtreamPortal portal;
  final XtreamCredentials credentials;
  final XtHttpAdapter http;
  final XtreamLogger? logger;
  final XtreamClientOptions options;

  XtreamClient(
    this.portal,
    this.credentials, {
    XtreamClientOptions? options,
    XtHttpAdapter? http,
    this.logger,
  }) : options = options ?? const XtreamClientOptions(),
       http = http ?? createDefaultHttpAdapter();

  /// Fetches account and server info from `player_api.php`.
  Future<XtUserAndServerInfo> getUserAndServerInfo({
    XtCancellationToken? cancel,
  }) async {
    final res = await _sendRequest(
      logPrefix: 'GET',
      path: ['player_api.php'],
      cancel: cancel,
    );
    try {
      final map =
          jsonDecode(utf8.decode(await res.bodyBytes)) as Map<String, dynamic>;
      final userMap = map['user_info'] as Map<String, dynamic>?;
      final serverMap = map['server_info'] as Map<String, dynamic>?;
      if (userMap == null || serverMap == null) {
        throw const XtParseError('Missing user_info or server_info');
      }
      final user = XtUserInfo.fromJson(userMap);
      final server = XtServerInfo.fromJson(serverMap);
      return XtUserAndServerInfo(user: user, server: server);
    } on XtError {
      rethrow;
    } catch (err, st) {
      throw XtParseError(
        'Invalid JSON from ${Redactor.redactUrl(res.url.toString())}',
        cause: err,
        stackTrace: st,
      );
    }
  }

  /// Live categories.
  Future<List<XtCategory>> getLiveCategories({
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson('get_live_categories', cancel: cancel);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => XtCategory.fromJson(json, kind: 'live'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for live categories');
  }

  /// VOD categories.
  Future<List<XtCategory>> getVodCategories({
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson('get_vod_categories', cancel: cancel);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => XtCategory.fromJson(json, kind: 'vod'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for VOD categories');
  }

  /// Series categories.
  Future<List<XtCategory>> getSeriesCategories({
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson('get_series_categories', cancel: cancel);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => XtCategory.fromJson(json, kind: 'series'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for series categories');
  }

  /// Live streams (optionally filtered by category id).
  Future<List<XtLiveChannel>> getLiveStreams({
    String? categoryId,
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson(
      'get_live_streams',
      extra: {if (categoryId != null) 'category_id': categoryId},
      cancel: cancel,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(XtLiveChannel.fromJson)
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for live streams');
  }

  /// VOD streams (optionally filtered by category id).
  Future<List<XtVodItem>> getVodStreams({
    String? categoryId,
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson(
      'get_vod_streams',
      extra: {if (categoryId != null) 'category_id': categoryId},
      cancel: cancel,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(XtVodItem.fromJson)
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for VOD streams');
  }

  /// Series list (optionally filtered by category id).
  Future<List<XtSeriesItem>> getSeries({
    String? categoryId,
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson(
      'get_series',
      extra: {if (categoryId != null) 'category_id': categoryId},
      cancel: cancel,
    );
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(XtSeriesItem.fromJson)
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for series');
  }

  /// VOD details by stream id.
  Future<XtVodDetails> getVodInfo(
    int vodId, {
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson(
      'get_vod_info',
      extra: {'vod_id': '$vodId'},
      cancel: cancel,
    );
    if (data is Map<String, dynamic>) {
      return XtVodDetails.fromJson(data);
    }
    throw const XtParseError('Expected object for VOD details');
  }

  /// Series details by series id.
  Future<XtSeriesDetails> getSeriesInfo(
    int seriesId, {
    XtCancellationToken? cancel,
  }) async {
    final data = await _getJson(
      'get_series_info',
      extra: {'series_id': '$seriesId'},
      cancel: cancel,
    );
    if (data is Map<String, dynamic>) {
      return XtSeriesDetails.fromJson(data);
    }
    throw const XtParseError('Expected object for series details');
  }

  /// Short EPG for a live stream.
  /// Some portals require `epg_channel_id` instead of `stream_id`.
  /// Provide either [epgChannelId] or [streamId] (prefer [epgChannelId] when known).
  Future<List<XtEpgEntry>> getShortEpg({
    int? streamId,
    String? epgChannelId,
    int limit = 10,
    XtCancellationToken? cancel,
  }) async {
    if (streamId == null && (epgChannelId == null || epgChannelId.isEmpty)) {
      throw const XtUnsupportedError(
        'getShortEpg requires streamId or epgChannelId',
      );
    }

    final Map<String, String> params = {'limit': '$limit'};
    if (streamId != null) {
      params['stream_id'] = '$streamId';
    } else {
      params['epg_channel_id'] = epgChannelId!;
    }

    final data = await _getJson('get_short_epg', extra: params, cancel: cancel);

    List? list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      list = data['epg_listings'] ?? data['listings'] ?? data['results'];
    }

    if (list is List) {
      final entries = list
          .whereType<Map<String, dynamic>>()
          .map(XtEpgEntry.fromJson)
          .toList(growable: false);

      if (entries.isNotEmpty ||
          streamId == null ||
          epgChannelId == null ||
          epgChannelId.isEmpty) {
        return entries;
      }
    }

    // Retry with epgChannelId if streamId returned empty results
    if (streamId != null && epgChannelId != null && epgChannelId.isNotEmpty) {
      final data = await _getJson(
        'get_short_epg',
        extra: {'epg_channel_id': epgChannelId, 'limit': '$limit'},
        cancel: cancel,
      );
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(XtEpgEntry.fromJson)
            .toList(growable: false);
      }
    }

    return const [];
  }

  /// Ping the portal by calling player_api.php (auth check) and measuring latency.
  Future<XtHealth> ping({XtCancellationToken? cancel}) async {
    final started = DateTime.now();
    final res = await _sendRequest(
      logPrefix: 'PING',
      path: ['player_api.php'],
      cancel: cancel,
    );
    // Consume and discard the response body to avoid keeping the
    // HttpClient connection alive, which can delay process exit.
    await res.body.drain<void>();
    final latency = DateTime.now().difference(started);
    return XtHealth(ok: res.ok, statusCode: res.statusCode, latency: latency);
  }

  /// Fetch server capabilities if available (tolerates missing endpoint with sane defaults).
  Future<XtCapabilities> capabilities() async {
    XtResponse? res;
    try {
      res = await _sendRequest(
        logPrefix: 'GET',
        path: ['player_api.php'],
        query: {'action': 'get_server_capabilities'},
      );
      final data = jsonDecode(utf8.decode(await res.bodyBytes));
      if (data is Map<String, dynamic>) {
        return XtCapabilities.fromJson(data);
      }
      // Some servers might nest under a key
      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        return XtCapabilities.fromJson(data.first as Map<String, dynamic>);
      }
    } on XtNetworkError {
      rethrow;
    } on XtAuthError {
      rethrow;
    } catch (err, st) {
      logger?.warn('Failed to parse capabilities, using defaults: $err\n$st');
    } finally {
      // Ensure body stream is drained if partially read
      try {
        await res?.body.drain<void>();
      } catch (_) {}
    }
    return const XtCapabilities();
  }

  /// Fetches an M3U playlist from `get.php` and returns a stream of entries.
  /// This is optional and depends on server support.
  /// [output] controls the stream file extension preference: 'hls' or 'ts'.
  Stream<XtM3uEntry> getM3u({
    String output = 'hls',
    XtCancellationToken? cancel,
  }) async* {
    final res = await _sendRequest(
      logPrefix: 'GET',
      path: ['get.php'],
      query: {'type': 'm3u_plus', 'output': output},
      accept:
          'application/x-mpegURL, audio/mpegurl, text/plain;q=0.5, */*;q=0.1',
      cancel: cancel,
    );
    // Stream-parse the playlist
    yield* parseM3u(res.body);
  }

  /// Fetches XMLTV feed from `xmltv.php` and returns a stream of events.
  /// This is optional and depends on server support. The event stream yields
  /// channels and programmes as they are parsed.
  Stream<XtXmltvEvent> getXmltv({XtCancellationToken? cancel}) async* {
    final res = await _sendRequest(
      logPrefix: 'GET',
      path: ['xmltv.php'],
      accept: 'application/xml, text/xml;q=0.9, */*;q=0.1',
      cancel: cancel,
    );
    yield* parseXmltv(res.body);
  }

  // Private helpers

  void _log(String prefix, Uri url) {
    logger?.info('$prefix ${Redactor.redactUrl(url.toString())}');
  }

  Never _raiseHttp(Uri url, int code) {
    final msg = 'HTTP $code ${Redactor.redactUrl(url.toString())}';
    if (code == 401 || code == 403) throw XtAuthError(msg);
    if (code == 451) throw XtPortalBlockedError(msg);
    throw XtNetworkError(msg);
  }

  Future<XtResponse> _sendRequest({
    required String logPrefix,
    required List<String> path,
    Map<String, String>? query,
    String accept = 'application/json',
    XtCancellationToken? cancel,
  }) async {
    final url = _buildPath(portal.baseUri, path).replace(
      queryParameters: {
        'username': credentials.username,
        'password': credentials.password,
        ...?query,
      },
    );
    _log(logPrefix, url);

    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept': accept,
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );

    if (!res.ok) _raiseHttp(url, res.statusCode);
    return res;
  }

  Future<dynamic> _getJson(
    String action, {
    Map<String, String>? extra,
    XtCancellationToken? cancel,
  }) async {
    final res = await _sendRequest(
      logPrefix: 'GET',
      path: ['player_api.php'],
      query: {'action': action, ...?extra},
      cancel: cancel,
    );
    try {
      return jsonDecode(utf8.decode(await res.bodyBytes));
    } catch (err, st) {
      throw XtParseError(
        'Invalid JSON from ${Redactor.redactUrl(res.url.toString())}',
        cause: err,
        stackTrace: st,
      );
    }
  }
}

Uri _buildPath(Uri base, List<String> add) {
  final segments = <String>[
    ...base.pathSegments.where((segment) => segment.isNotEmpty),
    ...add,
  ];
  return base.replace(path: segments.join('/'));
}
