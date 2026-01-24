import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/video_player_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelVideoPlayer', () {
    final methodChannel = MethodChannelVideoPlayer();
    const channelName = 'video_player';

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    test('playVideo returns expected result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'playVideo') {
            return [100, 300];
          }
          return null;
        },
      );

      final result = await methodChannel.playVideo(
        playerConfigJsonString: '{"videoUrl": "https://example.com/video.m3u8"}',
      );

      expect(result, isNotNull);
      expect(result, [100, 300]);
    });

    test('playVideo handles null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'playVideo') {
            return null;
          }
          return null;
        },
      );

      final result = await methodChannel.playVideo(
        playerConfigJsonString: '{"videoUrl": "https://example.com/video.m3u8"}',
      );

      expect(result, isNull);
    });

    test('playVideo handles platform exception gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'playVideo') {
            throw PlatformException(code: 'ERROR', message: 'Native error');
          }
          return null;
        },
      );

      final result = await methodChannel.playVideo(
        playerConfigJsonString: '{"videoUrl": "https://example.com/video.m3u8"}',
      );

      expect(result, isNull);
    });

    test('close completes without error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'close') {
            return null;
          }
          return null;
        },
      );

      await expectLater(
        methodChannel.close(),
        completes,
      );
    });

    test('close handles platform exception gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (MethodCall call) async {
          if (call.method == 'close') {
            throw PlatformException(code: 'ERROR', message: 'Close failed');
          }
          return null;
        },
      );

      await expectLater(
        methodChannel.close(),
        completes,
      );
    });
  });
}
