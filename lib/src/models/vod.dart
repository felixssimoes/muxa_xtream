/// VOD (movie) list entry.
class XtVodItem {
  final int streamId;
  final String name;
  final String categoryId;
  final String? posterUrl;

  const XtVodItem({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.posterUrl,
  });
}

/// VOD details.
class XtVodDetails {
  final int streamId;
  final String name;
  final String? plot;
  final double? rating;
  final int? year;
  final Duration? duration;
  final String? posterUrl;

  const XtVodDetails({
    required this.streamId,
    required this.name,
    this.plot,
    this.rating,
    this.year,
    this.duration,
    this.posterUrl,
  });
}
