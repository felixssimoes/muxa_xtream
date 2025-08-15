import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  HttpServer? server;
  late Uri base;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://localhost:${server!.port}');
    unawaited(() async {
      await for (final req in server!) {
        final path = req.uri.path;
        if (path.endsWith('/player_api.php')) {
          final qp = req.uri.queryParameters;
          // Simple auth gate
          if (qp['username'] != 'alice' || qp['password'] != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }
          final body = jsonEncode({
            'user_info': {
              'username': 'alice',
              'account_status': 'active',
              'exp_date': '1700000000',
              'max_connections': '2',
              'trial': '0',
            },
            'server_info': {
              'base_url': base.toString(),
              'timezone': 'UTC',
              'https': '0',
            },
          });
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/json');
          req.response.write(body);
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      }
    }());
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('getUserAndServerInfo returns parsed models', () async {
    final portal = XtreamPortal(base);
    final client = XtreamClient(
      portal,
      const XtreamCredentials(username: 'alice', password: 'secret'),
      http: XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          connectTimeout: Duration(milliseconds: 200),
          receiveTimeout: Duration(milliseconds: 500),
        ),
      ),
    );

    final info = await client.getUserAndServerInfo();
    expect(info.user.username, 'alice');
    expect(info.user.active, isTrue);
    expect(info.user.maxConnections, 2);
    expect(info.server.baseUrl.toString(), base.toString());
  });

  test('getUserAndServerInfo throws XtAuthError on 403', () async {
    final portal = XtreamPortal(base);
    final client = XtreamClient(
      portal,
      const XtreamCredentials(username: 'alice', password: 'wrong'),
      http: XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          connectTimeout: Duration(milliseconds: 200),
          receiveTimeout: Duration(milliseconds: 300),
        ),
      ),
    );

    expect(() => client.getUserAndServerInfo(), throwsA(isA<XtAuthError>()));
  });
}
