import 'dart:async';
import 'dart:convert';

import '../models/m3u.dart';

/// Parses M3U/M3U8 playlists from a byte stream into [XtM3uEntry] items.
/// Tolerant to spacing and minor format variants; ignores comments/blank lines.
Stream<XtM3uEntry> parseM3u(Stream<List<int>> bytes) async* {
  String? pendingName;
  Map<String, String> pendingAttrs = {};

  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('#EXTM3U')) {
      // header; ignore
      continue;
    }
    if (trimmed.startsWith('#EXTINF')) {
      // Example: #EXTINF:-1 tvg-id="ch.id" tvg-name="Channel" tvg-logo="http://logo" group-title="News", Channel Name
      final comma = trimmed.indexOf(',');
      final info = comma >= 0 ? trimmed.substring(0, comma) : trimmed;
      final title = comma >= 0 ? trimmed.substring(comma + 1).trim() : '';
      pendingName = title;
      pendingAttrs = _parseExtinfAttrs(info);
      continue;
    }
    if (trimmed.startsWith('#')) {
      // other tags/comments ignored
      continue;
    }
    // URL line; pair with last EXTINF title/attrs when present
    final url = trimmed;
    final name = pendingName ?? url;
    final attrs = pendingAttrs;
    final entry = XtM3uEntry(
      url: url,
      name: name,
      tvgId: attrs['tvg-id'] ?? attrs['tvg_id'],
      groupTitle: attrs['group-title'] ?? attrs['group_title'],
      logoUrl: attrs['tvg-logo'] ?? attrs['tvg_logo'],
      attrs: attrs,
    );
    yield entry;
    // reset pending after emission
    pendingName = null;
    pendingAttrs = {};
  }
}

Map<String, String> _parseExtinfAttrs(String info) {
  // strip leading '#EXTINF:...'
  final attrPart = info.replaceFirst(RegExp(r'^#EXTINF:[^ ]*'), '').trim();
  final attrs = <String, String>{};
  // Parse key=value pairs with quoted values ("..." or '...') and tolerate spacing.
  var i = 0;
  while (i < attrPart.length) {
    // skip spaces
    while (i < attrPart.length && attrPart.codeUnitAt(i) == 0x20) {
      i++;
    }
    if (i >= attrPart.length) break;

    // read key
    final startKey = i;
    while (i < attrPart.length) {
      final c = attrPart.codeUnitAt(i);
      final isWord =
          (c >= 0x30 && c <= 0x39) || // 0-9
          (c >= 0x41 && c <= 0x5A) || // A-Z
          (c >= 0x61 && c <= 0x7A) || // a-z
          c == 0x5F || // _
          c == 0x2D; // -
      if (!isWord) break;
      i++;
    }
    if (i == startKey) {
      i++;
      continue;
    }
    final key = attrPart.substring(startKey, i);

    // skip spaces
    while (i < attrPart.length && attrPart.codeUnitAt(i) == 0x20) {
      i++;
    }
    if (i >= attrPart.length || attrPart[i] != '=') {
      continue;
    }
    i++; // skip '='
    while (i < attrPart.length && attrPart.codeUnitAt(i) == 0x20) {
      i++;
    }
    if (i >= attrPart.length) break;

    String value = '';
    final ch = attrPart[i];
    if (ch == '"' || ch == '\'') {
      final quote = ch;
      i++; // skip opening quote
      final valStart = i;
      while (i < attrPart.length && attrPart[i] != quote) {
        i++;
      }
      value = attrPart.substring(valStart, i);
      if (i < attrPart.length) i++; // skip closing quote
    } else {
      final valStart = i;
      while (i < attrPart.length && attrPart.codeUnitAt(i) != 0x20) {
        i++;
      }
      value = attrPart.substring(valStart, i);
    }

    if (key.isNotEmpty) {
      attrs[key] = value;
    }
  }
  return attrs;
}
