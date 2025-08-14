import 'redaction.dart';

typedef XtLogSink = void Function(String level, String message);

class XtreamLogger {
  final XtLogSink _sink;

  XtreamLogger(this._sink);

  void debug(String msg) => _log('DEBUG', msg);
  void info(String msg) => _log('INFO', msg);
  void warn(String msg) => _log('WARN', msg);
  void error(String msg) => _log('ERROR', msg);

  void _log(String level, String msg) {
    _sink(level, Redactor.redactText(msg));
  }
}
