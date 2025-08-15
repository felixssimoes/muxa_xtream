import 'package:test/test.dart';
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
      final user = XtUserInfo.fromJson(json);
      expect(user.username, 'alice');
      expect(user.active, isTrue);
      expect(user.maxConnections, 3);
      expect(user.trial, isFalse);
      expect(user.expiresAt, isNotNull);
      expect(user.expiresAt!.isUtc, isTrue);
    });

    test('server info infers https', () {
      final server = XtServerInfo.fromJson({
        'base_url': 'https://portal.example.com',
      });
      expect(server.baseUrl.host, 'portal.example.com');
      expect(server.https, isTrue);
    });

    test('category parsing', () {
      final category = XtCategory.fromJson({
        'category_id': '10',
        'category_name': 'News',
      }, kind: 'live');
      expect(category.id, '10');
      expect(category.name, 'News');
      expect(category.kind, 'live');
    });

    test('live channel variants', () {
      final live = XtLiveChannel.fromJson({
        'stream_id': '12',
        'title': 'Channel A',
        'category_id': '1',
        'stream_icon': 'http://logo',
        'epg_channel_id': 'ch.a',
      });
      expect(live.streamId, 12);
      expect(live.name, 'Channel A');
      expect(live.logoUrl, 'http://logo');
      expect(live.categoryId, '1');
      expect(live.epgChannelId, 'ch.a');
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
      final series = XtSeriesItem.fromJson({
        'series_id': '5',
        'name': 'Show',
        'category_id': '22',
      });
      expect(series.seriesId, 5);

      final episode = XtEpisode.fromJson({
        'id': 9,
        'title': 'Ep1',
        'season_number': '2',
        'episode_number': '7',
        'duration_seconds': 1500,
        'plot': 'plot',
      });
      expect(episode.season, 2);
      expect(episode.episode, 7);
      expect(episode.duration, const Duration(seconds: 1500));

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
      final epg = XtEpgEntry.fromJson({
        'epg_channel_id': 'ch1',
        'start': '2025-01-01T12:00:00Z',
        'end': '2025-01-01T13:00:00+00:00',
        'title': 'News',
        'description': 'desc',
      });
      expect(epg.channelId, 'ch1');
      expect(epg.startUtc.isUtc, isTrue);
      expect(epg.endUtc.difference(epg.startUtc), const Duration(hours: 1));
    });

    test('capabilities boolean-like parsing', () {
      final caps = XtCapabilities.fromJson({
        'short_epg': 'yes',
        'extended_epg': 'no',
        'm3u': 1,
        'xmltv': 0,
      });
      expect(caps.supportsShortEpg, isTrue);
      expect(caps.supportsExtendedEpg, isFalse);
      expect(caps.supportsM3u, isTrue);
      expect(caps.supportsXmltv, isFalse);
    });
  });
}
