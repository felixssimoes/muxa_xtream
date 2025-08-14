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
}
