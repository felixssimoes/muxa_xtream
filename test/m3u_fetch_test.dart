import 'dart:async';
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
          if (!req.uri.path.endsWith('/get.php')) {
            req.response.statusCode = 404;
            await req.response.close();
            continue;
          }
          final qp = req.uri.queryParameters;
          if (qp['username'] != 'alice' || qp['password'] != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }
          final playlist =
              '#EXTM3U\n'
              '#EXTINF:-1 tvg-id="ch1" group-title="News", Channel 1\n'
              '${base.replace(path: '/live/1.m3u8')}\n'
              '#EXTINF:-1, Channel 2\n'
              '${base.replace(path: '/live/2.ts')}\n';
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/x-mpegurl');
          req.response.write(playlist);
          await req.response.close();
        } catch (_) {}
      }
    }());
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('getM3u fetches and parses entries', () async {
    final client = XtreamClient(
      XtreamPortal(base),
      const XtreamCredentials(username: 'alice', password: 'secret'),
      http: XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          connectTimeout: Duration(milliseconds: 200),
          receiveTimeout: Duration(milliseconds: 400),
        ),
      ),
    );
    final entries = await client.getM3u().toList();
    expect(entries.length, 2);
    expect(entries.first.tvgId, 'ch1');
    expect(entries.first.groupTitle, 'News');
    expect(entries.first.url, endsWith('/live/1.m3u8'));
    expect(entries.last.url, endsWith('/live/2.ts'));
  });

  test('auth error on get.php', () async {
    final client = XtreamClient(
      XtreamPortal(base),
      const XtreamCredentials(username: 'alice', password: 'nope'),
      http: XtDefaultHttpAdapter(),
    );
    expect(() => client.getM3u().toList(), throwsA(isA<XtAuthError>()));
  });
}
