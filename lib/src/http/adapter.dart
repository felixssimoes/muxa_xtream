import 'dart:async';
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

  /// Create a request for the adapter. Use [timeout] to override adapter
  /// defaults and [cancel] to support cooperative cancellation.
  const XtRequest({
    required this.url,
    this.method = XtHttpMethod.get,
    this.headers = const {},
    this.timeout,
    this.cancel,
  });

  /// Returns a copy with selected fields replaced.
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
  final Stream<List<int>> body;
  final Uri url; // Final URL after redirects

  const XtResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.url,
  });

  /// True when [statusCode] is in the 2xx range.
  bool get ok => statusCode >= 200 && statusCode < 300;

  /// Collects the response body into a single byte list.
  Future<Uint8List> get bodyBytes async {
    final chunks = await body.toList();
    return Uint8List.fromList(chunks.expand((x) => x).toList());
  }
}

/// Adapter interface to abstract platform HTTP stacks.
///
/// Implementations should:
/// - Support GET and HEAD
/// - Respect per-request timeouts and headers
/// - Throw [XtNetworkError] for connectivity/timeouts/TLS issues
/// - Avoid leaking secrets in thrown messages (use redaction internally)
abstract class XtHttpAdapter {
  /// Execute a GET request.
  Future<XtResponse> get(XtRequest request);

  /// Execute a HEAD request.
  Future<XtResponse> head(XtRequest request);
}
