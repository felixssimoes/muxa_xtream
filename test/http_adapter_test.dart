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

    // Simple router
    unawaited(() async {
      await for (final req in server!) {
        try {
          final path = req.uri.path;
          if (path == '/echo-headers') {
            final val = req.headers.value('X-Test') ?? '';
            final body = 'X-Test:$val';
            req.response.statusCode = 200;
            req.response.headers.set('Content-Type', 'text/plain');
            req.response.write(body);
            await req.response.close();
          } else if (path == '/redirect') {
            final to = req.uri.queryParameters['to'] ?? '/dest';
            final loc = base.replace(path: to).toString();
            req.response.statusCode = 302;
            req.response.headers.set('Location', loc);
            await req.response.close();
          } else if (path == '/dest') {
            req.response.statusCode = 200;
            req.response.write('ok');
            await req.response.close();
          } else if (path == '/slow') {
            final delayMs =
                int.tryParse(req.uri.queryParameters['ms'] ?? '200') ?? 200;
            await Future<void>.delayed(Duration(milliseconds: delayMs));
            req.response.statusCode = 200;
            req.response.write('slow');
            await req.response.close();
          } else {
            req.response.statusCode = 404;
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

  group('XtDefaultHttpAdapter', () {
    late XtDefaultHttpAdapter adapter;

    setUp(() {
      adapter = XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          followRedirects: true,
          maxRedirects: 5,
          connectTimeout: Duration(milliseconds: 200),
          receiveTimeout: Duration(milliseconds: 200),
          defaultHeaders: {'X-Default': 'D'},
        ),
      );
    });

    test('sends headers and receives body', () async {
      final url = base.replace(path: '/echo-headers');
      final res = await adapter.get(
        XtRequest(url: url, headers: {'X-Test': 'yes'}),
      );
      expect(res.ok, isTrue);
      final body = utf8.decode(res.bodyBytes);
      expect(body, 'X-Test:yes');
    });

    test('follows redirects and returns final URL', () async {
      final url = base.replace(
        path: '/redirect',
        queryParameters: {'to': '/dest'},
      );
      final res = await adapter.get(XtRequest(url: url));
      expect(res.ok, isTrue);
      expect(utf8.decode(res.bodyBytes), 'ok');
      expect(res.url.path, '/dest');
    });

    test('times out and redacts sensitive info in errors', () async {
      final slow = base.replace(
        path: '/slow',
        queryParameters: {
          'ms': '500',
          'username': 'alice',
          'password': 'secret',
        },
      );
      try {
        await adapter.get(
          XtRequest(url: slow, timeout: const Duration(milliseconds: 50)),
        );
        fail('expected timeout');
      } on XtNetworkError catch (err) {
        final msg = err.toString();
        expect(msg, contains('REDACTED'));
        expect(msg, isNot(contains('alice')));
        expect(msg, isNot(contains('secret')));
      }
    });
  });
}
