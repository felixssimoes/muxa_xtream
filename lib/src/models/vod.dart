import '../util/json.dart';

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

  factory XtVodItem.fromJson(Map<String, dynamic> json) {
    final streamId = asInt(json['stream_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final catId = (json['category_id'] ?? json['category'] ?? '') as String;
    final poster =
        (json['poster'] ??
                json['cover'] ??
                json['cover_big'] ??
                json['stream_icon'])
            as String?;
    return XtVodItem(
      streamId: streamId,
      name: name,
      categoryId: catId,
      posterUrl: poster,
    );
  }
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

  factory XtVodDetails.fromJson(Map<String, dynamic> json) {
    final streamId = asInt(json['stream_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final plot = json['plot'] as String?;
    final rating = asDouble(json['rating']);
    final year = asInt(json['year']);
    final durSec = asInt(json['duration']) ?? asInt(json['duration_seconds']);
    final duration = durSec != null ? Duration(seconds: durSec) : null;
    final poster =
        (json['poster'] ??
                json['cover'] ??
                json['cover_big'] ??
                json['stream_icon'])
            as String?;
    return XtVodDetails(
      streamId: streamId,
      name: name,
      plot: plot,
      rating: rating,
      year: year,
      duration: duration,
      posterUrl: poster,
    );
  }
}
