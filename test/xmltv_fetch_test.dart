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
          if (!req.uri.path.endsWith('/xmltv.php')) {
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
          final body =
              '<?xml version="1.0" encoding="UTF-8"?>\n'
              '<tv>\n'
              '  <channel id="ch1"><display-name>One</display-name></channel>\n'
              '  <programme start="20240101120000 +0000" channel="ch1">\n'
              '    <title>News</title>\n'
              '  </programme>\n'
              '</tv>';
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/xml');
          req.response.write(body);
          await req.response.close();
        } catch (_) {}
      }
    }());
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  test('getXmltv fetches and parses events', () async {
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
    final events = await client.getXmltv().toList();
    expect(events.whereType<XtXmltvChannel>().length, 1);
    expect(events.whereType<XtXmltvProgramme>().length, 1);
  });

  test('auth error on xmltv.php', () async {
    final client = XtreamClient(
      XtreamPortal(base),
      const XtreamCredentials(username: 'alice', password: 'nope'),
      http: XtDefaultHttpAdapter(),
    );
    expect(() => client.getXmltv().toList(), throwsA(isA<XtAuthError>()));
  });
}
