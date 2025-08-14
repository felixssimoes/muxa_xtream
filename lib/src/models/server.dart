import '../util/json.dart';

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

  factory XtServerInfo.fromJson(Map<String, dynamic> json) {
    final base =
        (json['base_url'] ?? json['url'] ?? json['host'] ?? '') as String;
    final name = json['server_name'] as String?;
    final tz = json['timezone'] as String?;
    final https =
        asBool(json['https']) ?? (base.startsWith('https') ? true : null);
    return XtServerInfo(
      baseUrl: Uri.parse(base),
      serverName: name,
      timezone: tz,
      https: https,
    );
  }
}
