import 'package:test/test.dart';
import 'package:muxa_xtream/muxa_xtream.dart';

void main() {
  group('Redactor', () {
    test('redacts credentials in URLs', () {
      final url =
          'http://example.com/player_api.php?username=alice&password=secret&token=abc';
      final out = Redactor.redactUrl(url);
      expect(out, isNot(contains('alice')));
      expect(out, isNot(contains('secret')));
      expect(out, isNot(contains('abc')));
      expect(out, contains('username=REDACTED'));
      expect(out, contains('password=REDACTED'));
      expect(out, contains('token=REDACTED'));
    });

    test('redacts sensitive headers', () {
      final headers = {
        'Authorization': 'Bearer token123',
        'Cookie': 'sid=secret',
        'X-Api-Key': 'key123',
        'Accept': 'application/json',
      };
      final out = Redactor.redactHeaders(headers);
      expect(out['Authorization'], 'Bearer REDACTED');
      expect(out['Cookie'], 'REDACTED');
      expect(out['X-Api-Key'], 'REDACTED');
      expect(out['Accept'], 'application/json');
    });

    test('redacts secrets in free text', () {
      final text =
          'Authorization: Bearer tok123 token=abc password=shh http://h.com?username=u&password=p';
      final out = Redactor.redactText(text);
      expect(out, contains('Authorization: Bearer REDACTED'));
      expect(out, contains('token=REDACTED'));
      expect(out, contains('password=REDACTED'));
      expect(out, isNot(contains('tok123')));
      expect(out, isNot(contains('abc')));
      expect(out, isNot(contains('shh')));
      expect(out, isNot(contains('username=u')));
      expect(out, isNot(contains('password=p')));
    });
  });
}
