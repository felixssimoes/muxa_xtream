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
      ..writeln('expires: ${info.user.expiresAt}')
      ..writeln('max connections: ${info.user.maxConnections}')
      ..writeln('Server: ${info.server.baseUrl} (https: ${info.server.https})');
  } on XtAuthError catch (err) {
    stderr.writeln('Auth error: $err');
    await mock?.close(force: true);
    exit(1);
  } on XtError catch (err) {
    stderr.writeln('Error: $err');
    await mock?.close(force: true);
    exit(2);
  }

  // Fetch and print categories and a few items from each catalog
  try {
    stdout.writeln('Fetching catalogs...');

    final liveCats = await client.getLiveCategories();
    stdout.writeln('Live categories: ${liveCats.length}');
    for (final category in liveCats.take(3)) {
      stdout.writeln('  - \'${category.name}\' (id=${category.id})');
    }
    if (liveCats.isNotEmpty) {
      final category = liveCats[1];
      final streams = await client.getLiveStreams(categoryId: category.id);
      if (streams.isNotEmpty) {
        final stream = streams.first;
        stdout.writeln(
          'First live in ${category.name}: \'${stream.name}\' (id=${stream.streamId})',
        );
        // Most portals work with streamId for short EPG. If a channel
        // returns empty, it may require epg_channel_id; our client will
        // retry internally when both are provided.
        final epg = await client.getShortEpg(
          streamId: stream.streamId,
          limit: 2,
        );
        if (epg.isEmpty) {
          stdout.writeln('  No EPG data available');
        } else {
          for (final epgEntry in epg) {
            stdout.writeln(
              '  EPG: ${epgEntry.startUtc.toIso8601String()} - ${epgEntry.endUtc.toIso8601String()} \'${epgEntry.title}\'',
            );
          }
        }
      }
    }

    final vodCats = await client.getVodCategories();
    stdout.writeln('VOD categories: ${vodCats.length}');
    for (final category in vodCats.take(3)) {
      stdout.writeln('  - \'${category.name}\' (id=${category.id})');
    }
    if (vodCats.isNotEmpty) {
      final vod = await client.getVodStreams(categoryId: vodCats.first.id);
      if (vod.isNotEmpty) {
        final vodItem = vod.first;
        stdout.writeln(
          'First VOD in ${vodCats.first.name}: \'${vodItem.name}\' (id=${vodItem.streamId})',
        );
        final vd = await client.getVodInfo(vodItem.streamId);
        stdout.writeln(
          '  VOD details: duration=${vd.duration}, rating=${vd.rating}',
        );
      }
    }

    final seriesCats = await client.getSeriesCategories();
    stdout.writeln('Series categories: ${seriesCats.length}');
    for (final category in seriesCats.take(3)) {
      stdout.writeln('  - \'${category.name}\' (id=${category.id})');
    }
    if (seriesCats.isNotEmpty) {
      final ser = await client.getSeries(categoryId: seriesCats.first.id);
      if (ser.isNotEmpty) {
        final seriesItem = ser.first;
        stdout.writeln(
          'First series in ${seriesCats.first.name}: \'${seriesItem.name}\' (id=${seriesItem.seriesId})',
        );
        final sd = await client.getSeriesInfo(seriesItem.seriesId);
        final season1 = sd.seasons.keys.isNotEmpty
            ? sd.seasons.keys.first
            : null;
        if (season1 != null && sd.seasons[season1]!.isNotEmpty) {
          final ep = sd.seasons[season1]!.first;
          stdout.writeln(
            '  Series details: S${ep.season}E${ep.episode} \'${ep.title}\'',
          );
        }
      }
    }
  } on XtError catch (err) {
    stderr.writeln('Catalog error: $err');
  }

  // Diagnostics: ping and capabilities
  try {
    final health = await client.ping();
    stdout.writeln(
      'Ping: ok=${health.ok} status=${health.statusCode} latency=${health.latency.inMilliseconds}ms',
    );
    final caps = await client.capabilities();
    stdout.writeln(
      'Capabilities: shortEPG=${caps.supportsShortEpg}, extEPG=${caps.supportsExtendedEpg}, m3u=${caps.supportsM3u}, xmltv=${caps.supportsXmltv}',
    );
  } on XtError catch (err) {
    stderr.writeln('Diag error: $err');
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

  // Demo M3U fetch and parse (optional)
  try {
    stdout.writeln('Fetching M3U playlist (first 2 entries)...');
    var count = 0;
    await for (final entry in client.getM3u().take(2)) {
      count++;
      final group = entry.groupTitle ?? '-';
      stdout.writeln('  M3U #$count: [$group] ${entry.name} -> ${entry.url}');
    }
    if (count == 0) stdout.writeln('  No M3U entries available');
  } on XtError catch (err) {
    stderr.writeln('M3U error: $err');
  }

  // Demo XMLTV fetch and parse (optional)
  try {
    stdout.writeln('Fetching XMLTV (first 3 events)...');
    var chSeen = 0;
    var prSeen = 0;
    await for (final ev in client.getXmltv()) {
      if (ev is XtXmltvChannel && chSeen < 2) {
        chSeen++;
        stdout.writeln(
          '  XMLTV channel: id=${ev.id} name=${ev.displayName ?? '-'} icon=${ev.iconUrl ?? '-'}',
        );
      } else if (ev is XtXmltvProgramme && prSeen < 1) {
        prSeen++;
        stdout.writeln(
          '  XMLTV programme: ch=${ev.channelId} ${ev.start.toIso8601String()} \'${ev.title ?? '-'}\'',
        );
      }
      if (chSeen + prSeen >= 3) break;
    }
    if (chSeen + prSeen == 0) stdout.writeln('  No XMLTV events available');
  } on XtError catch (err) {
    stderr.writeln('XMLTV error: $err');
  }

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
          final action = qp['action'];
          dynamic bodyObj;
          if (action == null) {
            bodyObj = {
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
            };
          } else {
            switch (action) {
              case 'get_live_categories':
                bodyObj = [
                  {'category_id': '1', 'category_name': 'News'},
                  {'category_id': '2', 'category_name': 'Sports'},
                ];
                break;
              case 'get_vod_categories':
                bodyObj = [
                  {'category_id': '10', 'category_name': 'Movies'},
                  {'category_id': '11', 'category_name': 'Documentary'},
                ];
                break;
              case 'get_series_categories':
                bodyObj = [
                  {'category_id': '20', 'category_name': 'Shows'},
                ];
                break;
              case 'get_live_streams':
                final cat = qp['category_id'] ?? '1';
                bodyObj = [
                  {
                    'stream_id': 12,
                    'name': 'Channel A',
                    'category_id': cat,
                    'stream_icon': 'http://logo',
                  },
                ];
                break;
              case 'get_vod_streams':
                final cat = qp['category_id'] ?? '10';
                bodyObj = [
                  {
                    'stream_id': 77,
                    'name': 'Movie',
                    'category_id': cat,
                    'cover_big': 'http://img',
                  },
                ];
                break;
              case 'get_series':
                final cat = qp['category_id'] ?? '20';
                bodyObj = [
                  {'series_id': '5', 'name': 'Show', 'category_id': cat},
                ];
                break;
              case 'get_short_epg':
                final now = DateTime.now().toUtc();
                bodyObj = [
                  {
                    'epg_channel_id': 'ch.a',
                    'start': now.toIso8601String(),
                    'end': now.add(const Duration(hours: 1)).toIso8601String(),
                    'title': 'News',
                    'description': 'daily news',
                  },
                ];
                break;
              case 'get_vod_info':
                final id = int.tryParse(qp['vod_id'] ?? '') ?? 0;
                bodyObj = {
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
                final id = int.tryParse(qp['series_id'] ?? '') ?? 0;
                bodyObj = {
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
          }
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/json');
          req.response.write(jsonEncode(bodyObj));
          await req.response.close();
        } else if (path.endsWith('/get.php')) {
          final qp = req.uri.queryParameters;
          if (qp['username'] != 'alice' || qp['password'] != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }
          final base = Uri.parse('http://localhost:${server.port}');
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
        } else if (path.endsWith('/xmltv.php')) {
          final qp = req.uri.queryParameters;
          if (qp['username'] != 'alice' || qp['password'] != 'secret') {
            req.response.statusCode = 403;
            await req.response.close();
            continue;
          }
          final xml =
              '<?xml version="1.0" encoding="UTF-8"?>\n'
              '<tv>\n'
              '  <channel id="ch1"><display-name>One</display-name></channel>\n'
              '  <programme start="20240101120000 +0000" channel="ch1">\n'
              '    <title>News</title>\n'
              '  </programme>\n'
              '</tv>';
          req.response.statusCode = 200;
          req.response.headers.set('Content-Type', 'application/xml');
          req.response.write(xml);
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
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      switch (arg) {
        case '--portal':
          if (index + 1 >= args.length) return null;
          opts = opts.copyWith(portal: args[++index]);
          break;
        case '--user':
          if (index + 1 >= args.length) return null;
          opts = opts.copyWith(user: args[++index]);
          break;
        case '--pass':
          if (index + 1 >= args.length) return null;
          opts = opts.copyWith(pass: args[++index]);
          break;
        case '--self-signed':
          opts = opts.copyWith(selfSigned: true);
          break;
        case '--probe':
          if (index + 1 >= args.length) return null;
          opts = opts.copyWith(probeUrl: args[++index]);
          break;
        case '--mock':
          opts = opts.copyWith(mock: true);
          break;
        case '--stream-id':
          if (index + 1 >= args.length) return null;
          final parsedStreamId = int.tryParse(args[++index]) ?? 1;
          opts = opts.copyWith(streamId: parsedStreamId);
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
