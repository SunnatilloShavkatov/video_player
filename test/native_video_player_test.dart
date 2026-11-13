import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/native_video_player.dart';

import 'fake_video_player_bridge.dart';

void main() {
  group('NativeVideoPlayer', () {
    late FakeVideoPlayerBridge bridge;
    late NativeVideoPlayer player;
    const config = '{"videoUrl": "https://example.com/video.m3u8"}';

    setUp(() {
      bridge = FakeVideoPlayerBridge();
      player = NativeVideoPlayer(bridge);
    });

    test('playVideo returns the position and duration in seconds', () async {
      bridge.result = [100, 300];

      final result = await player.playVideo(playerConfigJsonString: config);

      expect(result, isA<PlaybackCompleted>());
      expect((result as PlaybackCompleted).lastPositionSeconds, 100);
      expect(result.durationSeconds, 300);
      expect(bridge.playedConfigs, [config]);
    });

    test('playVideo maps a null result to cancelled', () async {
      bridge.result = null;

      expect(await player.playVideo(playerConfigJsonString: config), isA<PlaybackCancelled>());
    });

    test('playVideo rejects a malformed native response', () async {
      bridge.result = [1];

      expect(await player.playVideo(playerConfigJsonString: config), isA<PlaybackFailed>());
    });

    test('playVideo maps a native failure to PlaybackFailed', () async {
      bridge.failure = const NativeFailure(code: 'PLAYER_ALREADY_ACTIVE', message: 'A video player is already active');

      final result = await player.playVideo(playerConfigJsonString: config);

      expect(result, isA<PlaybackFailed>());
      expect((result as PlaybackFailed).error, isA<NativeFailure>());
    });

    test('close reaches the bridge', () async {
      await player.close();

      expect(bridge.closeCount, 1);
    });

    test('close swallows a native failure', () async {
      bridge.failure = const NativeFailure(code: 'ERROR', message: 'Close failed');

      await expectLater(player.close(), completes);
    });
  });
}
