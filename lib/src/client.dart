import 'dart:convert';

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

/// Minimal client focusing on account/server info.
class XtreamClient {
  final XtreamPortal portal;
  final XtreamCredentials creds;
  final XtHttpAdapter http;
  final XtreamLogger? logger;
  final XtreamClientOptions options;

  XtreamClient(
    this.portal,
    this.creds, {
    XtreamClientOptions? options,
    XtHttpAdapter? http,
    this.logger,
  }) : options = options ?? const XtreamClientOptions(),
       http = http ?? createDefaultHttpAdapter();

  void _log(String prefix, Uri url) {
    logger?.info('$prefix ${Redactor.redactUrl(url.toString())}');
  }

  Never _raiseHttp(Uri url, int code) {
    final msg = 'HTTP $code ${Redactor.redactUrl(url.toString())}';
    if (code == 401 || code == 403) throw XtAuthError(msg);
    if (code == 451) throw XtPortalBlockedError(msg);
    throw XtNetworkError(msg);
  }

  /// Fetches account and server info from `player_api.php`.
  Future<XtUserAndServerInfo> getUserAndServerInfo({
    XtCancellationToken? cancel,
  }) async {
    final url = _buildPath(portal.baseUri, ['player_api.php']).replace(
      queryParameters: {'username': creds.username, 'password': creds.password},
    );
    _log('GET', url);

    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );

    if (!res.ok) _raiseHttp(url, res.statusCode);

    try {
      final map =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
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
        'Invalid JSON from ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    }
  }

  /// Live categories.
  Future<List<XtCategory>> getLiveCategories({
    XtCancellationToken? cancel,
  }) async {
    final data = await _getAction('get_live_categories', cancel: cancel);
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
    final data = await _getAction('get_vod_categories', cancel: cancel);
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
    final data = await _getAction('get_series_categories', cancel: cancel);
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
    final data = await _getAction(
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
    final data = await _getAction(
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
    final data = await _getAction(
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
    final data = await _getAction(
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
    final data = await _getAction(
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

    Future<List<XtEpgEntry>> fetchEpg(Map<String, String> params) async {
      final data = await _getAction(
        'get_short_epg',
        extra: params,
        cancel: cancel,
      );
      List? list;
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['epg_listings'] ?? data['listings'] ?? data['results'];
      }
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(XtEpgEntry.fromJson)
            .toList(growable: false);
      }
      throw const XtParseError('Expected list for short EPG');
    }

    // Try streamId first if provided. If empty and epgChannelId is available, retry with it.
    if (streamId != null) {
      final first = await fetchEpg({
        'stream_id': '$streamId',
        'limit': '$limit',
      });
      if (first.isNotEmpty || epgChannelId == null || epgChannelId.isEmpty) {
        return first;
      }
      return fetchEpg({'epg_channel_id': epgChannelId, 'limit': '$limit'});
    }

    // Only epgChannelId provided
    return fetchEpg({'epg_channel_id': epgChannelId!, 'limit': '$limit'});
  }

  Future<dynamic> _getAction(
    String action, {
    Map<String, String>? extra,
    XtCancellationToken? cancel,
  }) async {
    final url = _buildPath(portal.baseUri, ['player_api.php']).replace(
      queryParameters: {
        'username': creds.username,
        'password': creds.password,
        'action': action,
        ...?extra,
      },
    );
    _log('GET', url);
    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept': 'application/json',
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );
    if (!res.ok) _raiseHttp(url, res.statusCode);
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (err, st) {
      throw XtParseError(
        'Invalid JSON from ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    }
  }

  /// Ping the portal by calling player_api.php (auth check) and measuring latency.
  Future<XtHealth> ping({XtCancellationToken? cancel}) async {
    final started = DateTime.now();
    final url = _buildPath(portal.baseUri, ['player_api.php']).replace(
      queryParameters: {'username': creds.username, 'password': creds.password},
    );
    _log('PING', url);
    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept': 'application/json',
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );
    final latency = DateTime.now().difference(started);
    final ok = res.ok;
    if (!ok) _raiseHttp(url, res.statusCode);
    return XtHealth(ok: ok, statusCode: res.statusCode, latency: latency);
  }

  /// Fetch server capabilities if available (tolerates missing endpoint with sane defaults).
  Future<XtCapabilities> capabilities() async {
    try {
      final data = await _getAction('get_server_capabilities');
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
    } catch (_) {
      // Fall through to defaults below
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
    final url = _buildPath(portal.baseUri, ['get.php']).replace(
      queryParameters: {
        'username': creds.username,
        'password': creds.password,
        'type': 'm3u_plus',
        'output': output,
      },
    );
    _log('GET', url);
    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept':
              'application/x-mpegURL, audio/mpegurl, text/plain;q=0.5, */*;q=0.1',
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );
    if (!res.ok) _raiseHttp(url, res.statusCode);
    // Stream-parse the playlist
    yield* parseM3u(Stream<List<int>>.value(res.bodyBytes));
  }

  /// Fetches XMLTV feed from `xmltv.php` and returns a stream of events.
  /// This is optional and depends on server support. The event stream yields
  /// channels and programmes as they are parsed.
  Stream<XtXmltvEvent> getXmltv({XtCancellationToken? cancel}) async* {
    final url = _buildPath(portal.baseUri, ['xmltv.php']).replace(
      queryParameters: {'username': creds.username, 'password': creds.password},
    );
    _log('GET', url);
    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept': 'application/xml, text/xml;q=0.9, */*;q=0.1',
        },
        timeout: options.receiveTimeout,
        cancel: cancel,
      ),
    );
    if (!res.ok) _raiseHttp(url, res.statusCode);
    yield* parseXmltv(Stream<List<int>>.value(res.bodyBytes));
  }
}

Uri _buildPath(Uri base, List<String> add) {
  final segs = <String>[
    ...base.pathSegments.where((segment) => segment.isNotEmpty),
    ...add,
  ];
  return base.replace(path: segs.join('/'));
}
