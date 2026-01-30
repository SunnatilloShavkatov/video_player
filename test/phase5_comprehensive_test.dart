import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player/src/video_player_view.dart';

/// Phase 5 Comprehensive Testing Suite
///
/// This test suite validates all requirements from PHASE 5:
/// 1. Flutter API & Controller Tests
/// 2. Flutter Navigation & Lifecycle
/// 3. PlaybackResult type safety
/// 4. Time values (seconds vs milliseconds)
/// 5. Controller disposal guards
/// 6. Stream behavior after dispose
///
/// Note: iOS/Android native tests require physical devices
/// and are documented separately in the test report.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1️⃣ Flutter API & Controller Tests', () {
    group('PlaybackResult Types', () {
      test('PlaybackCompleted returns correct time values in SECONDS', () {
        const result = PlaybackCompleted(
          lastPositionSeconds: 120, // 2 minutes
          durationSeconds: 300, // 5 minutes
        );

        expect(result.lastPositionSeconds, equals(120));
        expect(result.durationSeconds, equals(300));
        expect(result, isA<PlaybackResult>());
        expect(result, isA<PlaybackCompleted>());
      });

      test('PlaybackCompleted validates time constraints', () {
        // Valid: position <= duration
        expect(
          () => PlaybackCompleted(lastPositionSeconds: 100, durationSeconds: 200),
          returnsNormally,
        );

        // Invalid: negative position
        expect(
          () => PlaybackCompleted(lastPositionSeconds: -1, durationSeconds: 100),
          throwsA(isA<AssertionError>()),
        );

        // Invalid: negative duration
        expect(
          () => PlaybackCompleted(lastPositionSeconds: 0, durationSeconds: -1),
          throwsA(isA<AssertionError>()),
        );

        // Invalid: position > duration
        expect(
          () => PlaybackCompleted(lastPositionSeconds: 200, durationSeconds: 100),
          throwsA(isA<AssertionError>()),
        );
      });

      test('PlaybackCancelled is properly constructed', () {
        const result = PlaybackCancelled();

        expect(result, isA<PlaybackResult>());
        expect(result, isA<PlaybackCancelled>());
        expect(result.toString(), equals('PlaybackCancelled()'));
      });

      test('PlaybackFailed contains error information', () {
        final error = Exception('Network error');
        final stackTrace = StackTrace.current;
        final result = PlaybackFailed(error: error, stackTrace: stackTrace);

        expect(result, isA<PlaybackResult>());
        expect(result, isA<PlaybackFailed>());
        expect(result.error, equals(error));
        expect(result.stackTrace, equals(stackTrace));
      });

      test('PlaybackResult sealed class enables exhaustive pattern matching', () {
        void handleResult(PlaybackResult result) {
          switch (result) {
            case PlaybackCompleted():
              return;
            case PlaybackCancelled():
              return;
            case PlaybackFailed():
              return;
          }
        }

        // Should compile and run without errors
        handleResult(const PlaybackCompleted(lastPositionSeconds: 0, durationSeconds: 100));
        handleResult(const PlaybackCancelled());
        handleResult(PlaybackFailed(error: 'Test error'));
      });
    });

    group('VideoPlayer.playVideo() API', () {
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

      test('returns PlaybackCompleted with seconds when platform returns [int, int]', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel(channelName),
          (MethodCall call) async {
            if (call.method == 'playVideo') {
              // Platform returns SECONDS as integers
              return [45, 180]; // 45 seconds position, 180 seconds duration
            }
            return null;
          },
        );

        final result = await VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'https://example.com/video.m3u8',
            title: 'Test Video',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        );

        expect(result, isA<PlaybackCompleted>());
        final completed = result as PlaybackCompleted;
        expect(completed.lastPositionSeconds, equals(45)); // SECONDS
        expect(completed.durationSeconds, equals(180)); // SECONDS
      });

      test('returns PlaybackCancelled when platform returns null', () async {
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

        final result = await VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'https://example.com/video.m3u8',
            title: 'Test Video',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        );

        expect(result, isA<PlaybackCancelled>());
      });

      test('returns PlaybackFailed when platform throws PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel(channelName),
          (MethodCall call) async {
            if (call.method == 'playVideo') {
              throw PlatformException(
                code: 'VIDEO_ERROR',
                message: 'Failed to load video',
              );
            }
            return null;
          },
        );

        final result = await VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'https://example.com/video.m3u8',
            title: 'Test Video',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        );

        expect(result, isA<PlaybackFailed>());
        final failed = result as PlaybackFailed;
        expect(failed.error, isA<PlatformException>());
      });

      test('returns PlaybackFailed when platform returns invalid data', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel(channelName),
          (MethodCall call) async {
            if (call.method == 'playVideo') {
              return [100]; // Invalid: only 1 element instead of 2
            }
            return null;
          },
        );

        final result = await VideoPlayer.instance.playVideo(
          playerConfig: const PlayerConfiguration(
            videoUrl: 'https://example.com/video.m3u8',
            title: 'Test Video',
            qualityText: 'Quality',
            speedText: 'Speed',
            autoText: 'Auto',
            lastPosition: 0,
            playVideoFromAsset: false,
            assetPath: '',
            movieShareLink: '',
          ),
        );

        expect(result, isA<PlaybackFailed>());
        final failed = result as PlaybackFailed;
        expect(failed.error.toString(), contains('expected 2 elements'));
      });

      test('throws ArgumentError for invalid HTTPS URL', () {
        expect(
          () => VideoPlayer.instance.playVideo(
            playerConfig: const PlayerConfiguration(
              videoUrl: 'http://insecure.com/video.mp4', // HTTP not HTTPS
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
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for empty URL', () {
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
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for file:// URL', () {
        expect(
          () => VideoPlayer.instance.playVideo(
            playerConfig: const PlayerConfiguration(
              videoUrl: 'file:///path/to/video.mp4',
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
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('VideoPlayerViewController Disposal Guards', () {
      late VideoPlayerViewController controller;
      const String channelPrefix = 'plugins.video/video_player_view_';

      setUp(() {
        // Create controller with ID 0
        controller = VideoPlayerViewController._(0);

        // Set up mock method channel
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannel('${channelPrefix}0'),
          (MethodCall call) async {
            return null;
          },
        );
      });

      tearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannel('${channelPrefix}0'),
          null,
        );
      });

      test('play() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.play(),
          throwsA(isA<StateError>()),
        );
      });

      test('pause() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.pause(),
          throwsA(isA<StateError>()),
        );
      });

      test('seekTo() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.seekTo(seconds: 10.0),
          throwsA(isA<StateError>()),
        );
      });

      test('mute() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.mute(),
          throwsA(isA<StateError>()),
        );
      });

      test('unmute() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.unmute(),
          throwsA(isA<StateError>()),
        );
      });

      test('setUrl() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.setUrl(url: 'https://example.com/video.m3u8'),
          throwsA(isA<StateError>()),
        );
      });

      test('setAssets() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.setAssets(assets: 'videos/test.mp4'),
          throwsA(isA<StateError>()),
        );
      });

      test('getDuration() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.getDuration(),
          throwsA(isA<StateError>()),
        );
      });

      test('positionStream throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.positionStream,
          throwsA(isA<StateError>()),
        );
      });

      test('statusStream throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.statusStream,
          throwsA(isA<StateError>()),
        );
      });

      test('onDurationReady() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.onDurationReady((duration) {}),
          throwsA(isA<StateError>()),
        );
      });

      test('setEventListener() throws StateError after dispose', () async {
        await controller.dispose();

        expect(
          () => controller.setEventListener((data) {}),
          throwsA(isA<StateError>()),
        );
      });

      test('dispose() is idempotent (safe to call multiple times)', () async {
        await controller.dispose();
        await controller.dispose(); // Should not throw
        await controller.dispose(); // Should not throw

        // All methods should still throw StateError
        expect(() => controller.play(), throwsA(isA<StateError>()));
      });

      test('controller works normally before dispose', () async {
        // Should not throw
        await expectLater(controller.play(), completes);
        await expectLater(controller.pause(), completes);
        await expectLater(controller.getDuration(), completes);

        // Streams should be accessible
        expect(controller.positionStream, isA<Stream<double>>());
        expect(controller.statusStream, isA<Stream<PlayerStatus>>());
      });
    });

    group('Stream Behavior After Dispose', () {
      late VideoPlayerViewController controller;
      const String channelPrefix = 'plugins.video/video_player_view_';

      setUp(() {
        controller = VideoPlayerViewController._(0);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannel('${channelPrefix}0'),
          (MethodCall call) async => null,
        );
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannel('${channelPrefix}0'),
          null,
        );
      });

      test('positionStream can be listened to multiple times before dispose', () async {
        final stream1 = controller.positionStream;
        final stream2 = controller.positionStream;

        expect(stream1, isNotNull);
        expect(stream2, isNotNull);
        expect(identical(stream1, stream2), isTrue); // Same stream instance

        // Both subscriptions should work
        final sub1 = stream1.listen((pos) {});
        final sub2 = stream2.listen((pos) {});

        await sub1.cancel();
        await sub2.cancel();
        await controller.dispose();
      });

      test('statusStream can be listened to multiple times before dispose', () async {
        final stream1 = controller.statusStream;
        final stream2 = controller.statusStream;

        expect(stream1, isNotNull);
        expect(stream2, isNotNull);
        expect(identical(stream1, stream2), isTrue); // Same stream instance

        // Both subscriptions should work
        final sub1 = stream1.listen((status) {});
        final sub2 = stream2.listen((status) {});

        await sub1.cancel();
        await sub2.cancel();
        await controller.dispose();
      });

      test('streams do not emit after dispose', () async {
        final positions = <double>[];
        final statuses = <PlayerStatus>[];

        final posSub = controller.positionStream.listen(positions.add);
        final statusSub = controller.statusStream.listen(statuses.add);

        // Simulate some events before dispose
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          MethodChannel('${channelPrefix}0'),
          (MethodCall call) async {
            if (call.method == 'positionUpdate') {
              return null;
            }
            return null;
          },
        );

        await controller.dispose();

        // Try to trigger callbacks after dispose (simulating late native callbacks)
        // The controller should ignore these
        final channel = MethodChannel('${channelPrefix}0');
        try {
          // These would be called by native code after dispose
          // Controller should ignore them
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(const MethodCall('positionUpdate', 10.0)),
            (_) {},
          );
        } catch (_) {
          // Expected - channel is disposed
        }

        // Give time for any async processing
        await Future.delayed(const Duration(milliseconds: 10));

        // No events should have been added after dispose
        expect(positions, isEmpty);
        expect(statuses, isEmpty);

        await posSub.cancel();
        await statusSub.cancel();
      });
    });

    group('Enum Stability', () {
      test('ResizeMode has stable platform values', () {
        expect(ResizeMode.fit.value, equals('fit'));
        expect(ResizeMode.fill.value, equals('fill'));
        expect(ResizeMode.zoom.value, equals('zoom'));
      });

      test('ResizeMode.fromValue parses correctly', () {
        expect(ResizeMode.fromValue('fit'), equals(ResizeMode.fit));
        expect(ResizeMode.fromValue('fill'), equals(ResizeMode.fill));
        expect(ResizeMode.fromValue('zoom'), equals(ResizeMode.zoom));
      });

      test('ResizeMode.fromValue throws on invalid value', () {
        expect(
          () => ResizeMode.fromValue('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('PlayerStatus has stable platform values', () {
        expect(PlayerStatus.idle.value, equals('idle'));
        expect(PlayerStatus.buffering.value, equals('buffering'));
        expect(PlayerStatus.ready.value, equals('ready'));
        expect(PlayerStatus.playing.value, equals('playing'));
        expect(PlayerStatus.paused.value, equals('paused'));
        expect(PlayerStatus.ended.value, equals('ended'));
        expect(PlayerStatus.error.value, equals('error'));
      });

      test('PlayerStatus.fromValue parses correctly with fallback', () {
        expect(PlayerStatus.fromValue('idle'), equals(PlayerStatus.idle));
        expect(PlayerStatus.fromValue('playing'), equals(PlayerStatus.playing));
        expect(PlayerStatus.fromValue('invalid'), equals(PlayerStatus.idle)); // Fallback
      });
    });
  });

  group('2️⃣ Flutter Navigation & Lifecycle (Unit Tests)', () {
    // Note: Full navigation tests require integration testing with actual widgets
    // These unit tests verify the underlying mechanisms

    test('Multiple controller instances can coexist', () {
      final controller1 = VideoPlayerViewController._(0);
      final controller2 = VideoPlayerViewController._(1);

      expect(controller1, isNotNull);
      expect(controller2, isNotNull);
      expect(identical(controller1, controller2), isFalse);

      // Clean up
      controller1.dispose();
      controller2.dispose();
    });

    test('Controller disposal does not affect other controllers', () async {
      final controller1 = VideoPlayerViewController._(0);
      final controller2 = VideoPlayerViewController._(1);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.video/video_player_view_0'),
        (call) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.video/video_player_view_1'),
        (call) async => null,
      );

      await controller1.dispose();

      // Controller 2 should still work
      expect(() => controller2.positionStream, returnsNormally);
      await expectLater(controller2.play(), completes);

      // Controller 1 should be disposed
      expect(() => controller1.play(), throwsA(isA<StateError>()));

      await controller2.dispose();
    });
  });

  group('3️⃣ PlayerConfiguration Factory Constructors', () {
    test('PlayerConfiguration.remote creates valid config', () {
      final config = PlayerConfiguration.remote(
        videoUrl: 'https://example.com/video.m3u8',
        title: 'Test Video',
        lastPositionMillis: 30000, // 30 seconds in milliseconds
      );

      expect(config.videoUrl, equals('https://example.com/video.m3u8'));
      expect(config.title, equals('Test Video'));
      expect(config.lastPosition, equals(30000));
      expect(config.playVideoFromAsset, isFalse);
      expect(config.assetPath, isEmpty);
      expect(config.qualityText, equals('Quality'));
      expect(config.speedText, equals('Speed'));
      expect(config.autoText, equals('Auto'));
    });

    test('PlayerConfiguration.asset creates valid config', () {
      final config = PlayerConfiguration.asset(
        assetPath: 'videos/intro.mp4',
        title: 'Intro Video',
      );

      expect(config.assetPath, equals('videos/intro.mp4'));
      expect(config.title, equals('Intro Video'));
      expect(config.playVideoFromAsset, isTrue);
      expect(config.videoUrl, isEmpty);
      expect(config.lastPosition, equals(0));
    });

    test('PlayerConfiguration.remote supports optional parameters', () {
      final config = PlayerConfiguration.remote(
        videoUrl: 'https://example.com/video.m3u8',
        title: 'Test',
        lastPositionMillis: 15000,
        movieShareLink: 'https://share.link',
        enableScreenProtection: true,
        qualityText: 'Qualidade',
        speedText: 'Velocidade',
        autoText: 'Automático',
      );

      expect(config.lastPosition, equals(15000));
      expect(config.movieShareLink, equals('https://share.link'));
      expect(config.enableScreenProtection, isTrue);
      expect(config.qualityText, equals('Qualidade'));
      expect(config.speedText, equals('Velocidade'));
      expect(config.autoText, equals('Automático'));
    });
  });
}
