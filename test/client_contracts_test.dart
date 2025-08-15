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
          if (!req.uri.path.endsWith('/player_api.php')) {
            req.response.statusCode = 404;
            await req.response.close();
            continue;
          }

          final qp = req.uri.queryParameters;
          final user = qp['username'] ?? '';
          final pass = qp['password'] ?? '';

          // Scenarios via username for simplicity
          if (user == 'blocked') {
            req.response.statusCode = 451;
            await req.response.close();
            continue;
          }
          if (user == 'error500') {
            req.response.statusCode = 500;
            await req.response.close();
            continue;
          }
          if (user == 'html') {
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'text/html');
            req.response.write('<html>oops</html>');
            await req.response.close();
            continue;
          }

          if (user != 'alice' || pass != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }

          final action = qp['action'];
          if (action == 'get_live_streams') {
            final count = 1500;
            final list = List.generate(
              count,
              (i) => {
                'stream_id': i + 1,
                'name': 'Channel ${i + 1}',
                'category_id': '1',
                'stream_icon': 'http://logo/${i + 1}',
              },
            );
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'application/json');
            req.response.write(jsonEncode(list));
            await req.response.close();
          } else if (action == 'get_live_categories') {
            final body = [
              {'category_id': '1', 'category_name': 'News'},
            ];
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'application/json');
            req.response.write(jsonEncode(body));
            await req.response.close();
          } else {
            req.response.statusCode = 400;
            await req.response.close();
          }
        } catch (_) {
          // ignore server errors in tests
        }
      }
    }());
  });

  tearDownAll(() async {
    await server?.close(force: true);
  });

  XtreamClient clientWithUser(String user) => XtreamClient(
    XtreamPortal(base),
    XtreamCredentials(
      username: user,
      password: user == 'blocked'
          ? 'secret'
          : user == 'error500'
          ? 'secret'
          : user == 'html'
          ? 'secret'
          : 'secret',
    ),
    http: XtDefaultHttpAdapter(
      options: const XtDefaultHttpOptions(
        connectTimeout: Duration(milliseconds: 200),
        receiveTimeout: Duration(milliseconds: 400),
      ),
    ),
  );

  test('returns XtPortalBlockedError on 451', () async {
    final client = clientWithUser('blocked');
    expect(
      () => client.getLiveCategories(),
      throwsA(isA<XtPortalBlockedError>()),
    );
  });

  test('returns XtNetworkError on non-auth HTTP error', () async {
    final client = clientWithUser('error500');
    expect(() => client.getLiveCategories(), throwsA(isA<XtNetworkError>()));
  });

  test('returns XtParseError on non-JSON 200 response', () async {
    final client = clientWithUser('html');
    expect(() => client.getLiveCategories(), throwsA(isA<XtParseError>()));
  });

  test('handles large live stream lists efficiently', () async {
    final client = clientWithUser('alice');
    final live = await client.getLiveStreams(categoryId: '1');
    expect(live.length, 1500);
    expect(live.first.streamId, 1);
    expect(live.last.streamId, 1500);
  });
}
