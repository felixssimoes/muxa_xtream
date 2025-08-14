/// Server/portal information traits.
class XtServerInfo {
  final Uri baseUrl;
  final String? serverName;
  final String? timezone;
  final bool? https;

  const XtServerInfo({
    required this.baseUrl,
    this.serverName,
    this.timezone,
    this.https,
  });
}
