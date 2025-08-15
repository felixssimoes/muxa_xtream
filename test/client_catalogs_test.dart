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
          if (!(req.uri.path.endsWith('/player_api.php'))) {
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
            case 'get_live_categories':
              body = [
                {'category_id': '1', 'category_name': 'News'},
                {'category_id': '2', 'category_name': 'Sports'},
              ];
              break;
            case 'get_vod_categories':
              body = [
                {'category_id': '10', 'category_name': 'Movies'},
              ];
              break;
            case 'get_series_categories':
              body = [
                {'category_id': '20', 'category_name': 'Shows'},
              ];
              break;
            case 'get_live_streams':
              final cat = qp['category_id'] ?? '1';
              body = [
                {
                  'stream_id': 12,
                  'name': 'Channel A',
                  'category_id': cat,
                  'stream_icon': 'http://logo',
                },
              ];
              break;
            case 'get_vod_streams':
              body = [
                {
                  'stream_id': 77,
                  'name': 'Movie',
                  'category_id': '10',
                  'cover_big': 'http://img',
                },
              ];
              break;
            case 'get_series':
              body = [
                {'series_id': '5', 'name': 'Show', 'category_id': '20'},
              ];
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

  test('fetches live/vod/series categories', () async {
    final client = makeClient();
    final live = await client.getLiveCategories();
    expect(live, isNotEmpty);
    expect(live.first.kind, 'live');

    final vod = await client.getVodCategories();
    expect(vod.single.name, 'Movies');

    final series = await client.getSeriesCategories();
    expect(series.single.id, '20');
  });

  test('fetches live/vod/series lists', () async {
    final client = makeClient();
    final live = await client.getLiveStreams(categoryId: '1');
    expect(live.single.streamId, 12);
    expect(live.single.categoryId, '1');

    final vod = await client.getVodStreams();
    expect(vod.single.streamId, 77);

    final series = await client.getSeries();
    expect(series.single.seriesId, 5);
  });

  test('returns XtAuthError on bad creds', () async {
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
    expect(() => bad.getLiveCategories(), throwsA(isA<XtAuthError>()));
  });
}
