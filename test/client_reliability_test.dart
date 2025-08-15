import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:muxa_xtream/muxa_xtream.dart';
import 'package:test/test.dart';

void main() {
  HttpServer? server;
  late Uri base;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://localhost:${server!.port}');

    unawaited(() async {
      await for (final req in server!) {
        try {
          final path = req.uri.path;
          // Delay endpoint for EPG
          if (path.endsWith('/player_api.php')) {
            final qp = req.uri.queryParameters;
            final action = qp['action'];
            // emulate auth
            if (qp['username'] != 'alice' || qp['password'] != 'secret') {
              req.response.statusCode = 403;
              await req.response.close();
              continue;
            }
            if (action == 'get_short_epg') {
              // Slow respond so that cancel/timeout can trigger
              await Future<void>.delayed(const Duration(milliseconds: 300));
              final now = DateTime.now().toUtc();
              final body = [
                {
                  'epg_channel_id': 'ch',
                  'start': now.toIso8601String(),
                  'end': now.add(const Duration(hours: 1)).toIso8601String(),
                  'title': 'T',
                },
              ];
              req.response.statusCode = 200;
              req.response.headers.set('Content-Type', 'application/json');
              req.response.write(jsonEncode(body));
              await req.response.close();
            } else if (action == null) {
              // Ping path: delay to trigger timeout
              await Future<void>.delayed(const Duration(milliseconds: 200));
              req.response.statusCode = 200;
              req.response.headers.set('Content-Type', 'application/json');
              req.response.write(jsonEncode({'ok': true}));
              await req.response.close();
            } else {
              req.response.statusCode = 404;
              await req.response.close();
            }
          } else {
            req.response.statusCode = 404;
            await req.response.close();
          }
        } catch (_) {
          // ignore mock errors
        }
      }
    }());
  });

  tearDown(() async {
    await server?.close(force: true);
  });

  XtreamClient clientFactory({XtreamLogger? logger, Duration? recv}) {
    final portal = XtreamPortal(base);
    final creds = const XtreamCredentials(
      username: 'alice',
      password: 'secret',
    );
    final http = XtDefaultHttpAdapter();
    return XtreamClient(
      portal,
      creds,
      http: http,
      options: XtreamClientOptions(
        receiveTimeout: recv ?? const Duration(seconds: 5),
      ),
      logger: logger,
    );
  }

  group('XtreamClient reliability', () {
    test('cancellation propagates and redacts URL', () async {
      final client = clientFactory();
      final src = XtCancellationSource();
      // Cancel soon
      Timer(const Duration(milliseconds: 50), src.cancel);
      try {
        await client.getShortEpg(streamId: 1, limit: 1, cancel: src.token);
        fail('expected cancellation as XtNetworkError');
      } on XtNetworkError catch (err) {
        final msg = err.toString();
        expect(msg, contains('Cancelled'));
        expect(msg, contains('REDACTED'));
        expect(msg, isNot(contains('alice')));
        expect(msg, isNot(contains('secret')));
      }
    });

    test('client-level timeout classification with redaction', () async {
      final client = clientFactory(recv: const Duration(milliseconds: 50));
      try {
        await client.ping();
        fail('expected timeout as XtNetworkError');
      } on XtNetworkError catch (err) {
        final msg = err.toString();
        expect(msg, contains('Timeout'));
        expect(msg, contains('REDACTED'));
      }
    });

    test('logger redacts secrets in logs', () async {
      late String seen;
      final logger = XtreamLogger((level, message) => seen = '$level $message');
      clientFactory(logger: logger);
      // Force an auth failure to keep it simple but still produce a GET log.
      // We simulate wrong creds by constructing a new client with bad password.
      final bad = XtreamClient(
        XtreamPortal(base),
        const XtreamCredentials(username: 'alice', password: 'wrong'),
        http: XtDefaultHttpAdapter(),
        options: const XtreamClientOptions(
          receiveTimeout: Duration(milliseconds: 100),
        ),
        logger: logger,
      );
      try {
        await bad.getUserAndServerInfo();
      } catch (_) {
        // ignore; we only care that the log was emitted and redacted
      }
      expect(seen, contains('GET '));
      expect(seen, contains('REDACTED'));
      expect(seen, isNot(contains('alice')));
      expect(seen, isNot(contains('wrong')));
    });
  });
}
