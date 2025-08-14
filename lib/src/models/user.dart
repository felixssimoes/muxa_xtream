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
}
