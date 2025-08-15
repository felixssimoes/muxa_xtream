/// Simple health check result for ping().
class XtHealth {
  final bool ok;
  final int statusCode;
  final Duration latency;

  const XtHealth({
    required this.ok,
    required this.statusCode,
    required this.latency,
  });
}
