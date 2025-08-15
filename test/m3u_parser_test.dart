import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('M3U parser', () {
    test('parses EXTINF with attributes and URL', () async {
      const playlist =
          '#EXTM3U\n'
          '#EXTINF:-1 tvg-id="ch1" tvg-name="News" tvg-logo="http://logo" group-title="Info", News HD\n'
          'http://example.com/live/1.m3u8\n';
      final entries = await parseM3u(
        Stream.value(utf8.encode(playlist)),
      ).toList();
      expect(entries.length, 1);
      final e = entries.first;
      expect(e.name, 'News HD');
      expect(e.tvgId, 'ch1');
      expect(e.groupTitle, 'Info');
      expect(e.logoUrl, 'http://logo');
      expect(e.url, 'http://example.com/live/1.m3u8');
    });

    test('tolerates comments, blanks, and missing EXTINF', () async {
      const playlist = '#EXTM3U\n# comment\n\nhttp://example.com/only_url.ts\n';
      final entries = await parseM3u(
        Stream.value(utf8.encode(playlist)),
      ).toList();
      expect(entries.length, 1);
      expect(entries.first.name, 'http://example.com/only_url.ts');
    });
  });
}
