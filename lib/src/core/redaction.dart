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
    qp.forEach((k, v) {
      if (_sensitiveQueryKeys.contains(k.toLowerCase())) {
        qp[k] = _mask;
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
      var s = url;
      final pairs = [
        RegExp(r'(username=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(password=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(token=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(access_token=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(auth=)([^&\s]+)', caseSensitive: false),
        RegExp(r'(key=)([^&\s]+)', caseSensitive: false),
      ];
      for (final re in pairs) {
        s = s.replaceAllMapped(re, (m) => '${m.group(1)}$_mask');
      }
      return s;
    }
  }

  static Map<String, String> redactHeaders(Map<String, String> headers) {
    final out = <String, String>{};
    headers.forEach((k, v) {
      final kl = k.toLowerCase();
      if (_sensitiveHeaders.contains(kl)) {
        if (kl == 'authorization' && v.toLowerCase().startsWith('bearer ')) {
          out[k] = 'Bearer $_mask';
        } else {
          out[k] = _mask;
        }
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  /// Redact common secret patterns in free-form text.
  static String redactText(String text) {
    var s = text;
    // query params in text
    final anyKey = RegExp(
      r'((?:username|password|token|access_token|auth|key)=)([^&\s]+)',
      caseSensitive: false,
    );
    s = s.replaceAllMapped(anyKey, (m) => '${m.group(1)}$_mask');
    // Authorization: Bearer <token>
    s = s.replaceAllMapped(
      RegExp(
        r'(Authorization\s*:\s*Bearer\s+)([^\s\r\n]+)',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}$_mask',
    );
    // URLs with credentials in text
    s = s.replaceAllMapped(
      RegExp(r'https?://[^\s)]+'),
      (m) => redactUrl(m.group(0)!),
    );
    return s;
  }
}
