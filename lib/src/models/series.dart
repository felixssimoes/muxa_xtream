import '../util/json.dart';

/// Series list entry.
class XtSeriesItem {
  final int seriesId;
  final String name;
  final String categoryId;
  final String? posterUrl;

  const XtSeriesItem({
    required this.seriesId,
    required this.name,
    required this.categoryId,
    this.posterUrl,
  });

  factory XtSeriesItem.fromJson(Map<String, dynamic> json) {
    final id = asInt(json['series_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final catId = (json['category_id'] ?? json['category'] ?? '') as String;
    final poster =
        (json['poster'] ??
                json['cover'] ??
                json['cover_big'] ??
                json['stream_icon'])
            as String?;
    return XtSeriesItem(
      seriesId: id,
      name: name,
      categoryId: catId,
      posterUrl: poster,
    );
  }
}

/// Episode in a TV series.
class XtEpisode {
  final int id;
  final String title;
  final int season;
  final int episode;
  final Duration? duration;
  final String? plot;

  const XtEpisode({
    required this.id,
    required this.title,
    required this.season,
    required this.episode,
    this.duration,
    this.plot,
  });

  factory XtEpisode.fromJson(Map<String, dynamic> json) {
    final id = asInt(json['id']) ?? 0;
    final title = (json['title'] ?? json['name'] ?? '') as String;
    final season = asInt(json['season']) ?? asInt(json['season_number']) ?? 0;
    final ep = asInt(json['episode']) ?? asInt(json['episode_number']) ?? 0;
    final durSec = asInt(json['duration']) ?? asInt(json['duration_seconds']);
    final duration = durSec != null ? Duration(seconds: durSec) : null;
    final plot = json['plot'] as String?;
    return XtEpisode(
      id: id,
      title: title,
      season: season,
      episode: ep,
      duration: duration,
      plot: plot,
    );
  }
}

/// Series details including seasons/episodes.
class XtSeriesDetails {
  final int seriesId;
  final String name;
  final String? plot;
  final Map<int, List<XtEpisode>> seasons; // seasonNumber -> episodes
  final String? posterUrl;

  const XtSeriesDetails({
    required this.seriesId,
    required this.name,
    required this.seasons,
    this.plot,
    this.posterUrl,
  });

  factory XtSeriesDetails.fromJson(Map<String, dynamic> json) {
    final id = asInt(json['series_id'] ?? json['id']) ?? 0;
    final name = (json['name'] ?? json['title'] ?? '') as String;
    final plot = json['plot'] as String?;
    final poster =
        (json['poster'] ??
                json['cover'] ??
                json['cover_big'] ??
                json['stream_icon'])
            as String?;
    final seasonsMap = <int, List<XtEpisode>>{};
    final episodes = json['episodes'];
    if (episodes is Map<String, dynamic>) {
      episodes.forEach((seasonKey, list) {
        final seasonNum = int.tryParse(seasonKey) ?? 0;
        final eps = <XtEpisode>[];
        if (list is List) {
          for (final entry in list) {
            if (entry is Map<String, dynamic>) {
              eps.add(XtEpisode.fromJson(entry));
            }
          }
        }
        seasonsMap[seasonNum] = eps;
      });
    }
    return XtSeriesDetails(
      seriesId: id,
      name: name,
      plot: plot,
      posterUrl: poster,
      seasons: seasonsMap,
    );
  }
}
