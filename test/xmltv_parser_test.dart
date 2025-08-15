import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('XMLTV parser', () {
    test('parses channels and programmes', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<tv generator-info-name="test">
  <channel id="ch1">
    <display-name>Channel One</display-name>
    <icon src="http://logo/ch1.png"/>
  </channel>
  <channel id="ch2"><display-name>Two</display-name></channel>
  <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="ch1">
    <title>News</title>
    <desc>Daily news</desc>
    <category>News</category>
  </programme>
  <programme start="20240101130000 +0000" channel="ch2"><title>Show</title></programme>
</tv>''';

      final events = await parseXmltv(Stream.value(utf8.encode(xml))).toList();
      // Expect channel then programme events in order
      expect(events.whereType<XtXmltvChannel>().length, 2);
      expect(events.whereType<XtXmltvProgramme>().length, 2);

      final ch1 = events.whereType<XtXmltvChannel>().first;
      expect(ch1.id, 'ch1');
      expect(ch1.displayName, 'Channel One');
      expect(ch1.iconUrl, 'http://logo/ch1.png');

      final pr1 = events.whereType<XtXmltvProgramme>().first;
      expect(pr1.channelId, 'ch1');
      expect(pr1.title, 'News');
      expect(pr1.description, 'Daily news');
      expect(pr1.categories, contains('News'));
      expect(pr1.start.toUtc().toIso8601String(), '2024-01-01T12:00:00.000Z');
      expect(pr1.stop!.toUtc().toIso8601String(), '2024-01-01T13:00:00.000Z');
    });

    test('tolerates comments and spaces', () async {
      const xml = '''<?xml version="1.0"?>
<tv>
  <!-- a comment -->
  <channel id="c"><display-name> C </display-name></channel>
</tv>''';
      final events = await parseXmltv(Stream.value(utf8.encode(xml))).toList();
      final ch = events.whereType<XtXmltvChannel>().first;
      expect(ch.id, 'c');
      expect(ch.displayName!.trim(), 'C');
    });
  });
}
