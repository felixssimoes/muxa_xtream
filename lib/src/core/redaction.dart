class Redactor {
  static const _mask = 'REDACTED';

  static String mask(String value) => value.isEmpty ? value : _mask;

  static const List<String> _sensitiveQueryKeys = [
    'username',
    'password',
    'token',
    'access_token',
    'auth',
    'key',
  ];

  static const _sensitiveHeaders = {
    'authorization',
    'proxy-authorization',
    'authentication',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  static Uri redactUri(Uri uri) {
    final qp = Map<String, String>.from(uri.queryParameters);
    bool changed = false;
    qp.forEach((key, value) {
      if (_sensitiveQueryKeys.contains(key.toLowerCase())) {
        qp[key] = _mask;
        changed = true;
      }
    });
    if (!changed) return uri;
    return uri.replace(queryParameters: qp);
  }

  static String redactUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return redactUri(uri).toString();
    } catch (_) {
      // Best-effort string redaction.
      var str = url;
      final pairs = [
        RegExp(r'(username=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(password=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(token=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(access_token=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(auth=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(key=)([^&\s]+)', caseSensitive: false),
      ];
      for (final re in pairs) {
        str = str.replaceAllMapped(re, (match) => '${match.group(1)}$_mask');
      }
      return str;
    }
  }

  static Map<String, String> redactHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    headers.forEach((key, value) {
      final kl = key.toLowerCase();
      if (_sensitiveHeaders.contains(kl)) {
        if (kl == 'authorization' &&
            value.toLowerCase().startsWith('bearer ')) {
          out[key] = 'Bearer $_mask';
        } else {
          out[key] = _mask;
        }
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  /// Redact common secret patterns in free-form text.
  static String redactText(String text) {
    var str = text;
    // query params in text
    final anyKey = RegExp(
      r'((?:username|password|token|access_token|auth|key)=)([^&\s]+)',
      caseSensitive: false,
    );
    str = str.replaceAllMapped(anyKey, (match) => '${match.group(1)}$_mask');
    // Authorization: Bearer <token>
    str = str.replaceAllMapped(
      RegExp(
        r'(Authorization\s*:\s*Bearer\s+)([^\s\r\n]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}$_mask',
    );
    // URLs with credentials in text
    str = str.replaceAllMapped(
      RegExp(r'https?://[^\s)]+'),
      (match) => redactUrl(match.group(0)!),
    );
    return str;
  }
}
