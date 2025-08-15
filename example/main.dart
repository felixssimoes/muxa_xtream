import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:muxa_xtream/muxa_xtream.dart';

void main(List<String> args) async {
  var opts = _CliOptions.parse(args, Platform.environment);
  if (opts == null) {
    _printUsage();
    exitCode = 64; // usage
    return;
  }

  HttpServer? mock;
  if (opts.mock) {
    mock = await _startMockServer();
    final base = Uri.parse('http://localhost:${mock.port}');
    opts = opts.copyWith(
      portal: base.toString(),
      user: opts.user ?? 'alice',
      pass: opts.pass ?? 'secret',
    );
    stdout.writeln('Mock portal at $base');
  }

  final portal = XtreamPortal.parse(opts.portal!);
  final creds = XtreamCredentials(username: opts.user!, password: opts.pass!);

  final http = XtDefaultHttpAdapter(
    options: XtDefaultHttpOptions(
      allowSelfSignedTls: opts.selfSigned,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
      defaultHeaders: {
        'Accept': 'application/json, text/plain;q=0.9, */*;q=0.1',
      },
    ),
  );

  final client = XtreamClient(portal, creds, http: http);

  stdout.writeln('Fetching account/server info...');
  try {
    final info = await client.getUserAndServerInfo();
    stdout
      ..writeln('User: ${info.user.username} (active: ${info.user.active})')
      ..writeln('expires: ${info.user.expiresAt})')
      ..writeln('max connections: ${info.user.maxConnections}')
      ..writeln('Server: ${info.server.baseUrl} (https: ${info.server.https})');
  } on XtAuthError catch (e) {
    stderr.writeln('Auth error: $e');
    await mock?.close(force: true);
    exit(1);
  } on XtError catch (e) {
    stderr.writeln('Error: $e');
    await mock?.close(force: true);
    exit(2);
  }

  // Show URL builder examples
  final live = liveUrl(portal, creds, opts.streamId);
  final vod = vodUrl(portal, creds, opts.streamId);
  final series = seriesUrl(portal, creds, opts.streamId);
  stdout
    ..writeln('Sample URLs for streamId=${opts.streamId}:')
    ..writeln('  live:   $live')
    ..writeln('  vod:    $vod')
    ..writeln('  series: $series');

  if (opts.probeUrl != null) {
    final ext = await suggestStreamExtension(http, Uri.parse(opts.probeUrl!));
    stdout.writeln('Probed stream extension: .$ext');
  }

  await mock?.close(force: true);
}

Future<HttpServer> _startMockServer() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  unawaited(() async {
    await for (final req in server) {
      try {
        final path = req.uri.path;
        if (path.endsWith('/player_api.php')) {
          final qp = req.uri.queryParameters;
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
              'base_url': 'http://localhost:${server.port}',
              'timezone': 'UTC',
              'https': '0',
            },
          });
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/json');
          req.response.write(body);
          await req.response.close();
        } else if (path == '/hls.m3u8') {
          req.response.headers.set(
            'Content-Type',
            'application/vnd.apple.mpegurl',
          );
          req.response.statusCode = 200;
          req.response.write('#EXTM3U');
          await req.response.close();
        } else if (path == '/video.ts') {
          req.response.headers.set('Content-Type', 'video/mp2t');
          req.response.statusCode = 206; // support range probe
          req.response.write('x');
          await req.response.close();
        } else {
          req.response.statusCode = 404;
          await req.response.close();
        }
      } catch (_) {
        // ignore mock errors
      }
    }
  }());
  return server;
}

void _printUsage() {
  stdout.writeln('''
Usage:
  dart run example/main.dart --portal URL --user USER --pass PASS [--self-signed] [--probe URL]
  dart run example/main.dart --mock [--probe URL]

Options:
  --portal URL      Xtream portal base URL (e.g., https://host:port)
  --user USER       Username
  --pass PASS       Password
  --self-signed     Allow self-signed TLS (for dev/testing)
  --probe URL       Probe a stream URL to suggest extension
  --mock            Start a local mock portal (user=alice, pass=secret)
  --stream-id N     Stream id to use in sample URLs (default: 1)

Env vars (fallbacks): XT_PORTAL, XT_USER, XT_PASS
''');
}

class _CliOptions {
  final String? portal;
  final String? user;
  final String? pass;
  final bool selfSigned;
  final String? probeUrl;
  final bool mock;
  final int streamId;

  _CliOptions({
    this.portal,
    this.user,
    this.pass,
    this.selfSigned = false,
    this.probeUrl,
    this.mock = false,
    this.streamId = 1,
  });

  _CliOptions copyWith({
    String? portal,
    String? user,
    String? pass,
    bool? selfSigned,
    String? probeUrl,
    bool? mock,
    int? streamId,
  }) => _CliOptions(
    portal: portal ?? this.portal,
    user: user ?? this.user,
    pass: pass ?? this.pass,
    selfSigned: selfSigned ?? this.selfSigned,
    probeUrl: probeUrl ?? this.probeUrl,
    mock: mock ?? this.mock,
    streamId: streamId ?? this.streamId,
  );

  static _CliOptions? parse(List<String> args, Map<String, String> env) {
    var opts = _CliOptions(
      portal: env['XT_PORTAL'],
      user: env['XT_USER'],
      pass: env['XT_PASS'],
    );
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      switch (a) {
        case '--portal':
          if (i + 1 >= args.length) return null;
          opts = opts.copyWith(portal: args[++i]);
          break;
        case '--user':
          if (i + 1 >= args.length) return null;
          opts = opts.copyWith(user: args[++i]);
          break;
        case '--pass':
          if (i + 1 >= args.length) return null;
          opts = opts.copyWith(pass: args[++i]);
          break;
        case '--self-signed':
          opts = opts.copyWith(selfSigned: true);
          break;
        case '--probe':
          if (i + 1 >= args.length) return null;
          opts = opts.copyWith(probeUrl: args[++i]);
          break;
        case '--mock':
          opts = opts.copyWith(mock: true);
          break;
        case '--stream-id':
          if (i + 1 >= args.length) return null;
          final v = int.tryParse(args[++i]) ?? 1;
          opts = opts.copyWith(streamId: v);
          break;
        default:
          return null;
      }
    }
    // Validate
    if (!opts.mock) {
      if (opts.portal == null || opts.user == null || opts.pass == null) {
        return null;
      }
    }
    return opts;
  }
}
