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
}
