import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPlayer Error Handling', () {
    const channelName = 'video_player';

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    test('throws exception for invalid URL format', () {
      expect(
        () => VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'http://example.com/video.mp4',
            title: 'Test',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws exception for file URL', () {
      expect(
        () => VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'file:///etc/passwd',
            title: 'Test',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws exception for empty URL', () {
      expect(
        () => VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: '',
            title: 'Test',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('accepts valid HTTPS URL', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'playVideo') {
            return [0, 100];
          }
          return null;
        },
      );

      final result = await VideoPlayer.instance.playVideo(
        playerConfig: const PlayerConfiguration(
          videoUrl: 'https://example.com/video.m3u8',
          title: 'Test',
          qualityText: 'Quality',
          speedText: 'Speed',
          autoText: 'Auto',
          lastPosition: 0,
          playVideoFromAsset: false,
          assetPath: '',
          movieShareLink: '',
        ),
      );

      expect(result, isNotNull);
      expect(result, [0, 100]);
    });
  });
}
