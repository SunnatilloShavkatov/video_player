import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/utils/url_validator.dart';

void main() {
  group('UrlValidator', () {
    const validator = UrlValidator.instance;

    test('accepts valid HTTPS URLs', () {
      expect(validator.isNotValidHttpsUrl('https://example.com/video.mp4'), isFalse);
      expect(validator.isNotValidHttpsUrl('https://example.com/video.m3u8'), isFalse);
      expect(validator.isNotValidHttpsUrl('https://subdomain.example.com/path/video.mp4'), isFalse);
    });

    test('rejects HTTP URLs', () {
      expect(validator.isNotValidHttpsUrl('http://example.com/video.mp4'), isTrue);
      expect(validator.isNotValidHttpsUrl('http://example.com/video.m3u8'), isTrue);
    });

    test('rejects file URLs', () {
      expect(validator.isNotValidHttpsUrl('file:///etc/passwd'), isTrue);
      expect(validator.isNotValidHttpsUrl('file:///path/to/video.mp4'), isTrue);
    });

    test('rejects empty string', () {
      expect(validator.isNotValidHttpsUrl(''), isTrue);
      expect(validator.isNotValidHttpsUrl('   '), isTrue);
    });

    test('rejects invalid URLs', () {
      expect(validator.isNotValidHttpsUrl('not-a-url'), isTrue);
      expect(validator.isNotValidHttpsUrl('javascript:alert(1)'), isTrue);
      expect(validator.isNotValidHttpsUrl('data:text/html,<script>'), isTrue);
    });

    test('rejects URLs without host', () {
      expect(validator.isNotValidHttpsUrl('https://'), isTrue);
      expect(validator.isNotValidHttpsUrl('https:///path'), isTrue);
    });

    test('rejects relative URLs', () {
      expect(validator.isNotValidHttpsUrl('/path/to/video.mp4'), isTrue);
      expect(validator.isNotValidHttpsUrl('video.mp4'), isTrue);
    });
  });
}
