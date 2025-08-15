import 'dart:convert';

import 'core/errors.dart';
import 'core/logger.dart';
import 'core/models.dart';
import 'core/redaction.dart';
import 'http/adapter.dart';
import 'http/adapter_factory.dart';
import 'models/account.dart';
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
}

Uri _buildPath(Uri base, List<String> add) {
  final segs = <String>[
    ...base.pathSegments.where((s) => s.isNotEmpty),
    ...add,
  ];
  return base.replace(path: segs.join('/'));
}
