import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('XtError', () {
    test('toString includes type and redacts secrets', () {
      final msg =
          'Login failed for http://e.com/player_api.php?username=alice&password=secret';
      final err = XtAuthError(msg);
      final s = err.toString();
      expect(s, contains('XtAuthError'));
      expect(s, isNot(contains('alice')));
      expect(s, isNot(contains('secret')));
      expect(s, contains('password=REDACTED'));
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
