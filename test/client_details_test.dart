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
          dynamic body;
          switch (action) {
            case 'get_vod_info':
              final id = int.parse(qp['vod_id'] ?? '0');
              body = {
                'stream_id': id,
                'title': 'Movie$id',
                'plot': 'lorem',
                'rating': '8.0',
                'year': '2001',
                'duration': '3600',
                'poster': 'http://img',
              };
              break;
            case 'get_series_info':
              final id = int.parse(qp['series_id'] ?? '0');
              body = {
                'series_id': '$id',
                'name': 'Show$id',
                'plot': 'ipsum',
                'poster': 'http://img2',
                'episodes': {
                  '1': [
                    {
                      'id': 100,
                      'title': 'Ep1',
                      'season': 1,
                      'episode': 1,
                      'duration': '1800',
                    },
                  ],
                },
              };
              break;
            default:
              req.response.statusCode = 400;
              await req.response.close();
              continue;
          }
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/json');
          req.response.write(jsonEncode(body));
          await req.response.close();
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

  test('getVodInfo returns details', () async {
    final c = makeClient();
    final d = await c.getVodInfo(77);
    expect(d.streamId, 77);
    expect(d.name, 'Movie77');
    expect(d.duration, const Duration(seconds: 3600));
  });

  test('getSeriesInfo returns details with episodes', () async {
    final c = makeClient();
    final s = await c.getSeriesInfo(5);
    expect(s.seriesId, 5);
    expect(s.seasons[1]!.single.title, 'Ep1');
  });

  test('auth errors throw XtAuthError', () async {
    final bad = XtreamClient(
      XtreamPortal(base),
      const XtreamCredentials(username: 'alice', password: 'nope'),
      http: XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          connectTimeout: Duration(milliseconds: 200),
          receiveTimeout: Duration(milliseconds: 300),
        ),
      ),
    );
    expect(() => bad.getVodInfo(1), throwsA(isA<XtAuthError>()));
  });
}
