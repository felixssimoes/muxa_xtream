import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
          if (action == 'get_short_epg') {
            final now = DateTime.now().toUtc();
            final body = [
              {
                'epg_channel_id': 'ch.a',
                'start': now.toIso8601String(),
                'end': now.add(const Duration(hours: 1)).toIso8601String(),
                'title': 'News',
                'description': 'daily news',
              },
            ];
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'application/json');
            req.response.write(jsonEncode(body));
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

  XtreamClient makeClient() => XtreamClient(
    XtreamPortal(base),
    const XtreamCredentials(username: 'alice', password: 'secret'),
    http: XtDefaultHttpAdapter(
      options: const XtDefaultHttpOptions(
        connectTimeout: Duration(milliseconds: 200),
        receiveTimeout: Duration(milliseconds: 300),
      ),
    ),
  );

  test('getShortEpg returns entries', () async {
    final c = makeClient();
    final epg = await c.getShortEpg(streamId: 12, limit: 1);
    expect(epg.length, 1);
    expect(epg.first.title, 'News');
    expect(epg.first.startUtc.isUtc, isTrue);
  });

  test('auth error on EPG', () async {
    final bad = XtreamClient(
      XtreamPortal(base),
      const XtreamCredentials(username: 'alice', password: 'nope'),
      http: XtDefaultHttpAdapter(),
    );
    expect(() => bad.getShortEpg(streamId: 1), throwsA(isA<XtAuthError>()));
  });
}
