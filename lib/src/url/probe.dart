import '../http/adapter.dart';

/// Suggest a stream file extension by probing the URL with HEAD (fallback GET Range).
/// Returns one of: 'm3u8' (HLS) or 'ts' (MPEG-TS). Defaults to 'm3u8' if unknown.
Future<String> suggestStreamExtension(
  XtHttpAdapter http,
  Uri url, {
  Map<String, String> headers = const {},
  Duration? timeout,
}) async {
  final merged = <String, String>{...headers};
  // First try HEAD to avoid fetching body.
  try {
    final headRes = await http.head(
      XtRequest(url: url, headers: merged, timeout: timeout),
    );
    final ext = _inferFromHeaders(headRes.headers, url);
    if (ext != null) return ext;
  } catch (_) {
    // ignore and try GET Range
  }

  // Fallback: issue a ranged GET to trigger headers without large download.
  try {
    final rangeHeaders = <String, String>{'Range': 'bytes=0-0', ...merged};
    final getRes = await http.get(
      XtRequest(url: url, headers: rangeHeaders, timeout: timeout),
    );
    final ext = _inferFromHeaders(getRes.headers, url);
    if (ext != null) return ext;
  } catch (_) {
    // ignore and fall back to default
  }

  // Default to HLS as the safer choice for most providers.
  return 'm3u8';
}

String? _inferFromHeaders(Map<String, String> headers, Uri url) {
  String? ct = headers.entries
      .firstWhere(
        (e) => e.key.toLowerCase() == 'content-type',
        orElse: () => const MapEntry('', ''),
      )
      .value;
  ct = ct.isEmpty ? null : ct.toLowerCase();

  // URL suffix hints
  final path = url.path.toLowerCase();
  if (path.endsWith('.m3u8')) return 'm3u8';
  if (path.endsWith('.ts')) return 'ts';

  if (ct != null) {
    if (ct.contains('application/vnd.apple.mpegurl') ||
        ct.contains('application/x-mpegurl') ||
        ct.contains('audio/mpegurl') ||
        ct.contains('vnd.apple.mpegurl')) {
      return 'm3u8';
    }
    if (ct.contains('video/mp2t') || ct.contains('mpeg2-ts')) {
      return 'ts';
    }
  }
  return null;
}
