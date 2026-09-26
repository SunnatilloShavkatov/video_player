import 'dart:convert';

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
            subtitleText: 'Subtitles',
            subtitleSizeText: 'Subtitle Size',
            subtitleOffText: 'Off',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<ArgumentError>()),
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
            subtitleText: 'Subtitles',
            subtitleSizeText: 'Subtitle Size',
            subtitleOffText: 'Off',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<ArgumentError>()),
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
            subtitleText: 'Subtitles',
            subtitleSizeText: 'Subtitle Size',
            subtitleOffText: 'Off',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        ),
        throwsA(isA<ArgumentError>()),
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
          subtitleText: 'Subtitles',
          subtitleSizeText: 'Subtitle Size',
          subtitleOffText: 'Off',
          lastPosition: 0,
          playVideoFromAsset: false,
          assetPath: '',
          movieShareLink: '',
        ),
      );

      expect(result, isA<PlaybackCompleted>());
      expect((result as PlaybackCompleted).lastPositionSeconds, 0);
      expect(result.durationSeconds, 100);
    });

    test('serializes subtitles correctly in PlayerConfiguration', () {
      const track = SubtitleTrack(
        id: '227017',
        label: 'English',
        lang: 'en',
        isDefault: true,
        url: 'https://example.com/sub.vtt',
      );
      final config = PlayerConfiguration.remote(
        videoUrl: 'https://example.com/video.m3u8',
        title: 'Karate Kid',
        subtitles: const [track],
      );

      final map = config.toMap();
      expect(map['subtitles'], isA<List<dynamic>>());
      final subsList = map['subtitles'] as List<dynamic>;
      expect(subsList.length, 1);
      final subMap = subsList[0] as Map<String, dynamic>;
      expect(subMap['id'], '227017');
      expect(subMap['label'], 'English');
      expect(subMap['lang'], 'en');
      expect(subMap['is_default'], true);
      expect(subMap['url'], 'https://example.com/sub.vtt');
    });

    test('keyRequestHeaders defaults to empty map', () {
      final config = PlayerConfiguration.remote(videoUrl: 'https://example.com/video.m3u8', title: 'Test');

      expect(config.keyRequestHeaders, isEmpty);
      expect(config.toMap()['keyRequestHeaders'], <String, String>{});
    });

    test('sends keyRequestHeaders to the platform without leaking values in toString', () async {
      String? sentConfig;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          if (call.method == 'playVideo') {
            sentConfig = (call.arguments as Map<Object?, Object?>)['playerConfigJsonString'] as String?;
            return [0, 0];
          }
          return null;
        },
      );
      final config = PlayerConfiguration.remote(
        videoUrl: 'https://example.com/master.m3u8',
        title: 'Lesson',
        keyRequestHeaders: const {'Authorization': 'Bearer secret-token'},
      );

      await VideoPlayer.instance.playVideo(playerConfig: config);

      final decoded = jsonDecode(sentConfig!) as Map<String, dynamic>;
      expect(decoded['keyRequestHeaders'], {'Authorization': 'Bearer secret-token'});
      expect(config.toString(), contains('Authorization'));
      expect(config.toString(), isNot(contains('secret-token')));
    });
  });
}
