import 'redaction.dart';

typedef XtLogSink = void Function(String level, String message);

/// Simple pluggable logger with built-in redaction.
///
/// Wraps a sink function and ensures sensitive data is redacted from messages
/// before emitting.
class XtreamLogger {
  final XtLogSink _sink;

  XtreamLogger(this._sink);

  /// Emit a debug-level log message.
  void debug(String msg) => _log('DEBUG', msg);

  /// Emit an info-level log message.
  void info(String msg) => _log('INFO', msg);

  /// Emit a warning-level log message.
  void warn(String msg) => _log('WARN', msg);

  /// Emit an error-level log message.
  void error(String msg) => _log('ERROR', msg);

  void _log(String level, String msg) {
    _sink(level, Redactor.redactText(msg));
  }
}
