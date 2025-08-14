import '../core/models.dart';

/// Builds a live stream URL (no I/O) for Xtream-style portals.
/// Defaults to HLS (`.m3u8`); set [extension] to `ts` for TS fallback.
Uri liveUrl(
  XtreamPortal portal,
  XtreamCredentials creds,
  int streamId, {
  String extension = 'm3u8',
}) {
  return _buildPath(portal.baseUri, [
    'live',
    creds.username,
    creds.password,
    '${streamId.toString()}.$extension',
  ]);
}

/// Builds a VOD (movie) stream URL (no I/O).
/// Defaults to HLS (`.m3u8`); set [extension] to `ts` for TS fallback.
Uri vodUrl(
  XtreamPortal portal,
  XtreamCredentials creds,
  int streamId, {
  String extension = 'm3u8',
}) {
  return _buildPath(portal.baseUri, [
    'movie',
    creds.username,
    creds.password,
    '${streamId.toString()}.$extension',
  ]);
}

/// Builds a Series (episode) stream URL (no I/O).
/// Defaults to HLS (`.m3u8`); set [extension] to `ts` for TS fallback.
Uri seriesUrl(
  XtreamPortal portal,
  XtreamCredentials creds,
  int episodeId, {
  String extension = 'm3u8',
}) {
  return _buildPath(portal.baseUri, [
    'series',
    creds.username,
    creds.password,
    '${episodeId.toString()}.$extension',
  ]);
}

Uri _buildPath(Uri base, List<String> add) {
  final segs = <String>[
    ...base.pathSegments.where((s) => s.isNotEmpty),
    ...add,
  ];
  return base.replace(path: segs.join('/'));
}
