import 'dart:async';

/// Cooperative cancellation primitive for requests.
class XtCancellationToken {
  final Completer<void> _c = Completer<void>();

  /// A future that completes when cancellation is requested.
  Future<void> get whenCancelled => _c.future;

  /// Whether cancellation has been requested.
  bool get isCancelled => _c.isCompleted;

  /// Throws [XtCancelledError] if already cancelled.
  void throwIfCancelled() {
    if (isCancelled) throw const XtCancelledError('Operation cancelled');
  }

  void _cancel() {
    if (!_c.isCompleted) _c.complete();
  }
}

/// Owner/producer of a [XtCancellationToken]. Call [cancel] to signal.
class XtCancellationSource {
  final XtCancellationToken token = XtCancellationToken();

  void cancel() => token._cancel();
}

/// Error emitted when an operation is cancelled via [XtCancellationToken].
class XtCancelledError implements Exception {
  final String message;
  const XtCancelledError(this.message);
  @override
  String toString() => 'XtCancelledError: $message';
}
