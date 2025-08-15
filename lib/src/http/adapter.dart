import 'dart:typed_data';

import '../core/errors.dart';
import '../core/cancellation.dart';

/// HTTP method for Xtream requests.
enum XtHttpMethod { get, head }

/// Immutable request descriptor used by HTTP adapters.
class XtRequest {
  final Uri url;
  final XtHttpMethod method;
  final Map<String, String> headers;
  final Duration? timeout; // Per-request override
  final XtCancellationToken? cancel; // Cooperative cancellation

  const XtRequest({
    required this.url,
    this.method = XtHttpMethod.get,
    this.headers = const {},
    this.timeout,
    this.cancel,
  });

  XtRequest copyWith({
    Uri? url,
    XtHttpMethod? method,
    Map<String, String>? headers,
    Duration? timeout,
    XtCancellationToken? cancel,
  }) => XtRequest(
    url: url ?? this.url,
    method: method ?? this.method,
    headers: headers ?? this.headers,
    timeout: timeout ?? this.timeout,
    cancel: cancel ?? this.cancel,
  );
}

/// Immutable response data returned by adapters.
class XtResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;
  final Uri url; // Final URL after redirects

  const XtResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
    required this.url,
  });

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// Adapter interface to abstract platform HTTP stacks.
///
/// Implementations should:
/// - Support GET and HEAD
/// - Respect per-request timeouts and headers
/// - Throw [XtNetworkError] for connectivity/timeouts/TLS issues
/// - Avoid leaking secrets in thrown messages (use redaction internally)
abstract class XtHttpAdapter {
  Future<XtResponse> get(XtRequest request);
  Future<XtResponse> head(XtRequest request);
}
