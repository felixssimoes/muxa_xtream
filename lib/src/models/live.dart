import '../util/json.dart';

/// Live TV channel.
class XtLiveChannel {
  final int streamId;
  final String name;
  final String? logoUrl;
  final String categoryId;
  final String? epgChannelId;

  const XtLiveChannel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.logoUrl,
    this.epgChannelId,
  });

  factory XtLiveChannel.fromJson(Map<String, dynamic> json) {
    final streamId = asInt(json['stream_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final logo =
        (json['stream_icon'] ?? json['logo'] ?? json['icon']) as String?;
    final catId = (json['category_id'] ?? json['category'] ?? '') as String;
    final epgId = (json['epg_channel_id'] ?? json['epg_id']) as String?;
    return XtLiveChannel(
      streamId: streamId,
      name: name,
      categoryId: catId,
      logoUrl: logo,
      epgChannelId: epgId,
    );
  }
}
