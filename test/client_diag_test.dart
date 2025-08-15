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
        try {
          final qp = req.uri.queryParameters;
          if (!req.uri.path.endsWith('/player_api.php')) {
            req.response.statusCode = 404;
            await req.response.close();
            continue;
          }
          if (qp['username'] != 'alice' || qp['password'] != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }
          final action = qp['action'];
          if (action == null) {
            // account/server info
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'application/json');
            req.response.write(
              jsonEncode({
                'user_info': {'username': 'alice'},
                'server_info': {'base_url': base.toString()},
              }),
            );
            await req.response.close();
          } else if (action == 'get_server_capabilities') {
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'application/json');
            req.response.write(
              jsonEncode({
                'short_epg': '1',
                'extended_epg': '0',
                'm3u': '1',
                'xmltv': '1',
              }),
            );
            await req.response.close();
          } else {
            req.response.statusCode = 400;
            await req.response.close();
          }
        } catch (_) {}
      }
    }());
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  XtreamClient makeClient({String pass = 'secret'}) => XtreamClient(
    XtreamPortal(base),
    XtreamCredentials(username: 'alice', password: pass),
    http: XtDefaultHttpAdapter(
      options: const XtDefaultHttpOptions(
        connectTimeout: Duration(milliseconds: 200),
        receiveTimeout: Duration(milliseconds: 300),
      ),
    ),
  );

  test('ping returns ok with latency', () async {
    final client = makeClient();
    final health = await client.ping();
    expect(health.ok, isTrue);
    expect(health.statusCode, 200);
    expect(health.latency, isNotNull);
  });

  test('capabilities returns flags', () async {
    final client = makeClient();
    final caps = await client.capabilities();
    expect(caps.supportsShortEpg, isTrue);
    expect(caps.supportsExtendedEpg, isFalse);
    expect(caps.supportsM3u, isTrue);
    expect(caps.supportsXmltv, isTrue);
  });

  test('ping with bad creds throws auth error', () async {
    final client = makeClient(pass: 'nope');
    expect(() => client.ping(), throwsA(isA<XtAuthError>()));
  });
}
