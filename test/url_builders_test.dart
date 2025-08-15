import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('URL builders', () {
    test('default to m3u8 and have correct shape', () {
      final portal = XtreamPortal.parse('https://example.com');
      const creds = XtreamCredentials(username: 'u', password: 'p');

      final live = liveUrl(portal, creds, 10);
      expect(live.toString(), 'https://example.com/live/u/p/10.m3u8');

      final vod = vodUrl(portal, creds, 20);
      expect(vod.toString(), 'https://example.com/movie/u/p/20.m3u8');

      final series = seriesUrl(portal, creds, 30);
      expect(series.toString(), 'https://example.com/series/u/p/30.m3u8');
    });

    test('ts extension override works', () {
      final portal = XtreamPortal.parse('https://example.com/');
      const creds = XtreamCredentials(username: 'u', password: 'p');

      final liveTs = liveUrl(portal, creds, 1, extension: 'ts');
      expect(liveTs.path, '/live/u/p/1.ts');

      final vodTs = vodUrl(portal, creds, 2, extension: 'ts');
      expect(vodTs.path, '/movie/u/p/2.ts');

      final seriesTs = seriesUrl(portal, creds, 3, extension: 'ts');
      expect(seriesTs.path, '/series/u/p/3.ts');
    });
  });

  group('Probe helper', () {
    HttpServer? server;
    late Uri base;
    late XtDefaultHttpAdapter http;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://localhost:${server!.port}');
      http = XtDefaultHttpAdapter(
        options: const XtDefaultHttpOptions(
          followRedirects: true,
          maxRedirects: 2,
          connectTimeout: Duration(milliseconds: 300),
          receiveTimeout: Duration(milliseconds: 300),
        ),
      );

      unawaited(() async {
        await for (final req in server!) {
          final path = req.uri.path;
          if (path == '/hls.m3u8') {
            req.response.headers.set(
              'Content-Type',
              'application/vnd.apple.mpegurl',
            );
            req.response.statusCode = 200;
            if (req.method == 'GET') {
              req.response.write('#EXTM3U');
            }
            await req.response.close();
          } else if (path == '/ts-by-ct') {
            // No suffix; infer by Content-Type header
            req.response.headers.set('Content-Type', 'video/mp2t');
            req.response.statusCode = 200;
            await req.response.close();
          } else if (path == '/range-fallback') {
            // HEAD has no content-type; GET returns one
            if (req.method == 'HEAD') {
              req.response.statusCode = 200;
              await req.response.close();
            } else {
              // Expect a Range; still set CT
              req.response.headers.set('Content-Type', 'video/mp2t');
              req.response.statusCode = 206;
              req.response.write('x');
              await req.response.close();
            }
          } else if (path == '/unknown') {
            req.response.statusCode = 200;
            // No content-type; path without suffix
            req.response.write('data');
            await req.response.close();
          } else {
            req.response.statusCode = 404;
            await req.response.close();
          }
        }
      }());
    });

    tearDownAll(() async {
      await server?.close(force: true);
    });

    test('infers m3u8 from HEAD content-type and suffix', () async {
      final url = base.replace(path: '/hls.m3u8');
      final ext = await suggestStreamExtension(http, url);
      expect(ext, 'm3u8');
    });

    test('infers ts from HEAD content-type', () async {
      final url = base.replace(path: '/ts-by-ct');
      final ext = await suggestStreamExtension(http, url);
      expect(ext, 'ts');
    });

    test('falls back to GET Range when HEAD inconclusive', () async {
      final url = base.replace(path: '/range-fallback');
      final ext = await suggestStreamExtension(http, url);
      expect(ext, 'ts');
    });

    test('defaults to m3u8 when unknown', () async {
      final url = base.replace(path: '/unknown');
      final ext = await suggestStreamExtension(http, url);
      expect(ext, 'm3u8');
    });
  });
}
