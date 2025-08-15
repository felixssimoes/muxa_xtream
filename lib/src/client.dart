import 'dart:convert';

import 'core/errors.dart';
import 'core/logger.dart';
import 'core/models.dart';
import 'core/redaction.dart';
import 'http/adapter.dart';
import 'http/adapter_factory.dart';
import 'models/account.dart';
import 'models/category.dart';
import 'models/live.dart';
import 'models/vod.dart';
import 'models/series.dart';
import 'models/server.dart';
import 'models/user.dart';

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

  /// Fetches account and server info from `player_api.php`.
  Future<XtUserAndServerInfo> getUserAndServerInfo() async {
    final url = _buildPath(portal.baseUri, ['player_api.php']).replace(
      queryParameters: {'username': creds.username, 'password': creds.password},
    );
    logger?.info('GET ${Redactor.redactUrl(url.toString())}');

    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
        },
        timeout: options.receiveTimeout,
      ),
    );

    if (!res.ok) {
      final code = res.statusCode;
      final msg = 'HTTP $code for ${Redactor.redactUrl(url.toString())}';
      if (code == 401 || code == 403) {
        throw XtAuthError(msg);
      }
      if (code == 451) {
        throw XtPortalBlockedError(msg);
      }
      throw XtNetworkError(msg);
    }

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
    } catch (e, st) {
      throw XtParseError(
        'Invalid JSON from ${Redactor.redactUrl(url.toString())}',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Live categories.
  Future<List<XtCategory>> getLiveCategories() async {
    final data = await _getAction('get_live_categories');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => XtCategory.fromJson(e, kind: 'live'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for live categories');
  }

  /// VOD categories.
  Future<List<XtCategory>> getVodCategories() async {
    final data = await _getAction('get_vod_categories');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => XtCategory.fromJson(e, kind: 'vod'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for VOD categories');
  }

  /// Series categories.
  Future<List<XtCategory>> getSeriesCategories() async {
    final data = await _getAction('get_series_categories');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => XtCategory.fromJson(e, kind: 'series'))
          .toList(growable: false);
    }
    throw const XtParseError('Expected list for series categories');
  }

  /// Live streams (optionally filtered by category id).
  Future<List<XtLiveChannel>> getLiveStreams({String? categoryId}) async {
    final data = await _getAction(
      'get_live_streams',
      extra: {if (categoryId != null) 'category_id': categoryId},
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
  Future<List<XtVodItem>> getVodStreams({String? categoryId}) async {
    final data = await _getAction(
      'get_vod_streams',
      extra: {if (categoryId != null) 'category_id': categoryId},
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
  Future<List<XtSeriesItem>> getSeries({String? categoryId}) async {
    final data = await _getAction(
      'get_series',
      extra: {if (categoryId != null) 'category_id': categoryId},
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
  Future<XtVodDetails> getVodInfo(int vodId) async {
    final data = await _getAction('get_vod_info', extra: {'vod_id': '$vodId'});
    if (data is Map<String, dynamic>) {
      return XtVodDetails.fromJson(data);
    }
    throw const XtParseError('Expected object for VOD details');
  }

  /// Series details by series id.
  Future<XtSeriesDetails> getSeriesInfo(int seriesId) async {
    final data = await _getAction(
      'get_series_info',
      extra: {'series_id': '$seriesId'},
    );
    if (data is Map<String, dynamic>) {
      return XtSeriesDetails.fromJson(data);
    }
    throw const XtParseError('Expected object for series details');
  }

  Future<dynamic> _getAction(
    String action, {
    Map<String, String>? extra,
  }) async {
    final url = _buildPath(portal.baseUri, ['player_api.php']).replace(
      queryParameters: {
        'username': creds.username,
        'password': creds.password,
        'action': action,
        ...?extra,
      },
    );
    logger?.info('GET ${Redactor.redactUrl(url.toString())}');
    final res = await http.get(
      XtRequest(
        url: url,
        headers: {
          if (options.userAgent != null) 'User-Agent': options.userAgent!,
          ...options.defaultHeaders,
          'Accept': 'application/json',
        },
        timeout: options.receiveTimeout,
      ),
    );
    if (!res.ok) {
      final code = res.statusCode;
      final msg = 'HTTP $code for ${Redactor.redactUrl(url.toString())}';
      if (code == 401 || code == 403) throw XtAuthError(msg);
      if (code == 451) throw XtPortalBlockedError(msg);
      throw XtNetworkError(msg);
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e, st) {
      throw XtParseError(
        'Invalid JSON from ${Redactor.redactUrl(url.toString())}',
        cause: e,
        stackTrace: st,
      );
    }
  }
}

Uri _buildPath(Uri base, List<String> add) {
  final segs = <String>[
    ...base.pathSegments.where((s) => s.isNotEmpty),
    ...add,
  ];
  return base.replace(path: segs.join('/'));
}
