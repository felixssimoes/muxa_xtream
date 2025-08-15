import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('XtError', () {
    test('toString includes type and redacts secrets', () {
      final rawMessage =
          'Login failed for http://e.com/player_api.php?username=alice&password=secret';
      final err = XtAuthError(rawMessage);
      final msg = err.toString();
      expect(msg, contains('XtAuthError'));
      expect(msg, isNot(contains('alice')));
      expect(msg, isNot(contains('secret')));
      expect(msg, contains('password=REDACTED'));
    });

    test('subclasses are distinguishable', () {
      expect(const XtNetworkError('n').toString(), contains('XtNetworkError'));
      expect(const XtParseError('p').toString(), contains('XtParseError'));
      expect(
        const XtPortalBlockedError('b').toString(),
        contains('XtPortalBlockedError'),
      );
      expect(
        const XtUnsupportedError('u').toString(),
        contains('XtUnsupportedError'),
      );
    });
  });

  test('XtreamLogger redacts messages', () {
    final captured = <String>[];
    final logger = XtreamLogger((level, msg) => captured.add('$level:$msg'));
    logger.error('Authorization: Bearer tok123');
    expect(captured.single, contains('ERROR:Authorization: Bearer REDACTED'));
    expect(captured.single, isNot(contains('tok123')));
  });
}
