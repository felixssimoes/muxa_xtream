import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../core/errors.dart';
import '../core/cancellation.dart';
import '../core/redaction.dart';
import 'adapter.dart';

class XtDefaultHttpOptions {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool followRedirects;
  final int maxRedirects;
  final bool allowSelfSignedTls;
  final int maxGetRetries;
  final Duration baseBackoff; // e.g., 200ms
  final Map<String, String> defaultHeaders;

  const XtDefaultHttpOptions({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.allowSelfSignedTls = false,
    this.maxGetRetries = 2,
    this.baseBackoff = const Duration(milliseconds: 200),
    this.defaultHeaders = const {},
  });
}

/// Default HttpClient-based adapter (Dart VM / Flutter mobile/desktop).
class XtDefaultHttpAdapter implements XtHttpAdapter {
  final XtDefaultHttpOptions options;
  final HttpClient _client;
  final Random _rng;

  XtDefaultHttpAdapter({XtDefaultHttpOptions? options, HttpClient? client})
    : options = options ?? const XtDefaultHttpOptions(),
      _client = client ?? HttpClient(),
      _rng = Random() {
    _client.connectionTimeout = this.options.connectTimeout;
    _client.badCertificateCallback = this.options.allowSelfSignedTls
        ? (X509Certificate cert, String host, int port) => true
        : null;
  }

  @override
  Future<XtResponse> get(XtRequest request) async {
    return _withRetries(request, _once);
  }

  @override
  Future<XtResponse> head(XtRequest request) {
    return _once(request.copyWith(method: XtHttpMethod.head));
  }

  Future<XtResponse> _withRetries(
    XtRequest req,
    Future<XtResponse> Function(XtRequest) fn,
  ) async {
    var attempt = 0;
    while (true) {
      try {
        return await fn(req);
      } on XtNetworkError {
        if (attempt >= options.maxGetRetries ||
            req.method != XtHttpMethod.get) {
          rethrow;
        }
      }
      attempt++;
      final delay = _backoff(attempt);
      await Future<void>.delayed(delay);
    }
  }

  Duration _backoff(int attempt) {
    final base = options.baseBackoff.inMilliseconds * pow(2, attempt - 1);
    final jitter = _rng.nextInt(100); // 0..99ms
    return Duration(milliseconds: base.toInt() + jitter);
  }

  Future<XtResponse> _once(XtRequest request) async {
    final url = request.url;
    final timeout = request.timeout ?? options.receiveTimeout;
    try {
      // Fast-fail if already cancelled
      request.cancel?.throwIfCancelled();

      final req = await _client.openUrl(
        request.method == XtHttpMethod.head ? 'HEAD' : 'GET',
        url,
      );
      req.followRedirects = options.followRedirects;
      req.maxRedirects = options.maxRedirects;

      // Merge headers: defaults first, then request overrides.
      final headers = {...options.defaultHeaders, ...request.headers};
      headers.forEach((key, value) => req.headers.set(key, value));

      // Tie cancellation to closing the request: if cancelled, destroy
      // the underlying socket by closing the request with an error.
      final closeFuture = req.close();
      final guarded = request.cancel == null
          ? closeFuture
          : Future.any([
              closeFuture,
              request.cancel!.whenCancelled.then(
                (_) => throw const XtCancelledError('Operation cancelled'),
              ),
            ]);

      final resp = await guarded.timeout(timeout);
      final bytes = await resp.fold<BytesBuilder>(BytesBuilder(copy: false), (
        builder,
        data,
      ) {
        builder.add(data);
        return builder;
      });
      final body = bytes.takeBytes();
      final hdrs = <String, String>{};
      resp.headers.forEach((name, values) {
        if (values.isNotEmpty) hdrs[name] = values.join(',');
      });
      return XtResponse(
        statusCode: resp.statusCode,
        headers: hdrs,
        bodyBytes: body,
        url: resp.redirects.isNotEmpty ? resp.redirects.last.location : url,
      );
    } on XtCancelledError catch (err, st) {
      throw XtNetworkError(
        'Cancelled ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    } on TimeoutException catch (err, st) {
      throw XtNetworkError(
        'Timeout contacting ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    } on IOException catch (err, st) {
      throw XtNetworkError(
        'Network error for ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    } catch (err, st) {
      throw XtNetworkError(
        'Unexpected network error for ${Redactor.redactUrl(url.toString())}',
        cause: err,
        stackTrace: st,
      );
    }
  }
}
