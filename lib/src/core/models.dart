import 'redaction.dart';

/// Represents an Xtream-style portal base URL.
class XtreamPortal {
  final Uri baseUri;

  /// Create a portal from a [baseUri].
  XtreamPortal(this.baseUri);

  /// Parse and normalize a portal URL. Missing scheme defaults to `https://`.
  factory XtreamPortal.parse(String url) => XtreamPortal(_normalize(url));

  static Uri _normalize(String url) {
    final parsed = Uri.parse(url);
    if (parsed.scheme.isEmpty) {
      // Default to https when scheme is missing.
      return Uri.parse('https://$url');
    }
    return parsed;
  }

  @override
  String toString() => baseUri.toString();
}

/// User credentials for Xtream portals.
class XtreamCredentials {
  final String username;
  final String password;

  const XtreamCredentials({required this.username, required this.password});

  /// Redacted username for logs.
  String get maskedUsername => Redactor.mask(username);

  /// Redacted password token for logs.
  String get maskedPassword => Redactor.mask(password);

  @override
  String toString() =>
      'XtreamCredentials{username: $maskedUsername, password: REDACTED}';
}

/// Client configuration options.
class XtreamClientOptions {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final String? userAgent;
  final Map<String, String> defaultHeaders;

  /// Construct client options with sensible defaults.
  const XtreamClientOptions({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.userAgent,
    this.defaultHeaders = const {},
  });
}

/// Feature flags/capabilities.
class XtFeatures {
  final bool m3u; // supports M3U playlist endpoint
  final bool xmltv; // supports XMLTV EPG endpoint

  const XtFeatures({this.m3u = false, this.xmltv = false});

  /// Return a copy with selected flags updated.
  XtFeatures copyWith({bool? m3u, bool? xmltv}) =>
      XtFeatures(m3u: m3u ?? this.m3u, xmltv: xmltv ?? this.xmltv);
}
