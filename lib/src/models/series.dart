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
}
