import 'redaction.dart';

sealed class XtError implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const XtError(this.message, {this.cause, this.stackTrace});

  String get name => runtimeType.toString();

  @override
  String toString() {
    final redacted = Redactor.redactText(message);
    return '$name: $redacted';
  }
}

final class XtAuthError extends XtError {
  const XtAuthError(super.message, {super.cause, super.stackTrace});
}

final class XtNetworkError extends XtError {
  const XtNetworkError(super.message, {super.cause, super.stackTrace});
}

final class XtParseError extends XtError {
  const XtParseError(super.message, {super.cause, super.stackTrace});
}

final class XtPortalBlockedError extends XtError {
  const XtPortalBlockedError(super.message, {super.cause, super.stackTrace});
}

final class XtUnsupportedError extends XtError {
  const XtUnsupportedError(super.message, {super.cause, super.stackTrace});
}
