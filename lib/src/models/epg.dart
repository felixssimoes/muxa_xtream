import '../util/json.dart';

/// EPG entry for a program segment.
class XtEpgEntry {
  final String channelId; // provider channel/epg id
  final DateTime startUtc;
  final DateTime endUtc;
  final String title;
  final String? description;

  const XtEpgEntry({
    required this.channelId,
    required this.startUtc,
    required this.endUtc,
    required this.title,
    this.description,
  });

  factory XtEpgEntry.fromJson(Map<String, dynamic> json) {
    final ch = (json['channel_id'] ?? json['epg_channel_id'] ?? '') as String;
    final start = parseDateUtc(
      json['start'] ?? json['start_timestamp'] ?? json['start_time'],
    )!;
    final end = parseDateUtc(
      json['end'] ?? json['end_timestamp'] ?? json['end_time'],
    )!;
    final rawTitle = (json['title'] ?? json['name'] ?? '') as String;
    final rawDesc = json['description'] as String? ?? json['desc'] as String?;
    final title = maybeDecodeBase64Utf8(rawTitle);
    final desc = rawDesc == null ? null : maybeDecodeBase64Utf8(rawDesc);
    return XtEpgEntry(
      channelId: ch,
      startUtc: start,
      endUtc: end,
      title: title,
      description: desc,
    );
  }
}
