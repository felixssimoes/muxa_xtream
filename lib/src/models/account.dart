import 'user.dart';
import 'server.dart';

/// Combined account and server info returned by the portal.
class XtUserAndServerInfo {
  final XtUserInfo user;
  final XtServerInfo server;

  const XtUserAndServerInfo({required this.user, required this.server});
}
