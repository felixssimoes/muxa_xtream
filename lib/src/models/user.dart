import '../util/json.dart';

/// Account/user information returned by Xtream portals.
class XtUserInfo {
  final String username;
  final bool active;
  final DateTime? expiresAt; // UTC
  final int? maxConnections;
  final bool? trial;

  const XtUserInfo({
    required this.username,
    required this.active,
    this.expiresAt,
    this.maxConnections,
    this.trial,
  });

  factory XtUserInfo.fromJson(Map<String, dynamic> json) {
    // Common keys seen in Xtream-like APIs
    final username = (json['username'] ?? json['user'] ?? '') as String;
    // active might be provided as boolean, numeric, or status string
    final status = (json['status'] ?? json['account_status']) as String?;
    final active =
        asBool(json['active']) ??
        asBool(json['is_active']) ??
        (status != null ? asBool(status) : null) ??
        false;
    final expiresAt = parseDateUtc(json['exp_date'] ?? json['expires_at']);
    final maxConns = asInt(json['max_connections'] ?? json['max_cons']);
    final trial = asBool(json['is_trial'] ?? json['trial']);
    return XtUserInfo(
      username: username,
      active: active,
      expiresAt: expiresAt,
      maxConnections: maxConns,
      trial: trial,
    );
  }
}
