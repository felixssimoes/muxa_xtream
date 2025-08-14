import 'package:flutter_test/flutter_test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('JSON parsing', () {
    test('user info variants', () {
      final json = {
        'username': 'alice',
        'account_status': 'active',
        'exp_date': '1700000000', // epoch seconds
        'max_connections': '3',
        'trial': '0',
      };
      final u = XtUserInfo.fromJson(json);
      expect(u.username, 'alice');
      expect(u.active, isTrue);
      expect(u.maxConnections, 3);
      expect(u.trial, isFalse);
      expect(u.expiresAt, isNotNull);
      expect(u.expiresAt!.isUtc, isTrue);
    });

    test('server info infers https', () {
      final s = XtServerInfo.fromJson({
        'base_url': 'https://portal.example.com',
      });
      expect(s.baseUrl.host, 'portal.example.com');
      expect(s.https, isTrue);
    });

    test('category parsing', () {
      final c = XtCategory.fromJson({
        'category_id': '10',
        'category_name': 'News',
      }, kind: 'live');
      expect(c.id, '10');
      expect(c.name, 'News');
      expect(c.kind, 'live');
    });

    test('live channel variants', () {
      final l = XtLiveChannel.fromJson({
        'stream_id': '12',
        'title': 'Channel A',
        'category_id': '1',
        'stream_icon': 'http://logo',
        'epg_channel_id': 'ch.a',
      });
      expect(l.streamId, 12);
      expect(l.name, 'Channel A');
      expect(l.logoUrl, 'http://logo');
      expect(l.categoryId, '1');
      expect(l.epgChannelId, 'ch.a');
    });

    test('vod item and details variants', () {
      final item = XtVodItem.fromJson({
        'id': 77,
        'name': 'Movie',
        'category_id': '3',
        'cover_big': 'http://img',
      });
      expect(item.streamId, 77);
      expect(item.posterUrl, 'http://img');

      final details = XtVodDetails.fromJson({
        'stream_id': '77',
        'title': 'Movie',
        'plot': 'lorem',
        'rating': '7.5',
        'year': '1999',
        'duration': '5400',
        'poster': 'http://img2',
      });
      expect(details.streamId, 77);
      expect(details.rating, closeTo(7.5, 0.001));
      expect(details.year, 1999);
      expect(details.duration, const Duration(seconds: 5400));
      expect(details.posterUrl, 'http://img2');
    });

    test('series item, episode, and details mapping', () {
      final s = XtSeriesItem.fromJson({
        'series_id': '5',
        'name': 'Show',
        'category_id': '22',
      });
      expect(s.seriesId, 5);

      final ep = XtEpisode.fromJson({
        'id': 9,
        'title': 'Ep1',
        'season_number': '2',
        'episode_number': '7',
        'duration_seconds': 1500,
        'plot': 'plot',
      });
      expect(ep.season, 2);
      expect(ep.episode, 7);
      expect(ep.duration, const Duration(seconds: 1500));

      final details = XtSeriesDetails.fromJson({
        'series_id': 5,
        'title': 'Show',
        'episodes': {
          '1': [
            {'id': 1, 'title': 'S1E1', 'season': 1, 'episode': 1},
            {'id': 2, 'title': 'S1E2', 'season': 1, 'episode': 2},
          ],
        },
      });
      expect(details.seasons[1]!.length, 2);
      expect(details.seasons[1]![0].title, 'S1E1');
    });

    test('epg entry from iso times', () {
      final e = XtEpgEntry.fromJson({
        'epg_channel_id': 'ch1',
        'start': '2025-01-01T12:00:00Z',
        'end': '2025-01-01T13:00:00+00:00',
        'title': 'News',
        'description': 'desc',
      });
      expect(e.channelId, 'ch1');
      expect(e.startUtc.isUtc, isTrue);
      expect(e.endUtc.difference(e.startUtc), const Duration(hours: 1));
    });

    test('capabilities boolean-like parsing', () {
      final c = XtCapabilities.fromJson({
        'short_epg': 'yes',
        'extended_epg': 'no',
        'm3u': 1,
        'xmltv': 0,
      });
      expect(c.supportsShortEpg, isTrue);
      expect(c.supportsExtendedEpg, isFalse);
      expect(c.supportsM3u, isTrue);
      expect(c.supportsXmltv, isFalse);
    });
  });
}
