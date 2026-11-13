import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/video_player_platform_interface.dart';
import 'package:video_player/video_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Every call answers its callback exactly once; the repeated calls also exercise the proxy hand-over/release.
  testWidgets('a rejected configuration fails fast, 100 times, without hanging', (tester) async {
    for (var i = 0; i < 100; i++) {
      final result = await VideoPlayerPlatform.instance
          .playVideo(playerConfigJsonString: '{')
          .timeout(const Duration(seconds: 5));
      expect(result, isA<PlaybackFailed>(), reason: 'call $i');
    }
  });

  testWidgets('the failure carries the native code', (tester) async {
    final result = await VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: '{');

    final error = (result as PlaybackFailed).error;
    expect(error, isA<NativeFailure>());
    expect((error as NativeFailure).code, anyOf('JSON_ERROR', 'INVALID_ARGS'));
  });

  testWidgets('close without an active player completes', (tester) async {
    for (var i = 0; i < 50; i++) {
      await VideoPlayer.instance.close().timeout(const Duration(seconds: 5));
    }
  });

  testWidgets('full-screen player: second play is rejected, close ends the session', (tester) async {
    final config = PlayerConfiguration.remote(
      videoUrl: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
      title: 'Integration',
    );

    final first = VideoPlayer.instance.playVideo(playerConfig: config);
    await Future<void>.delayed(const Duration(seconds: 3));

    final second = await VideoPlayer.instance.playVideo(playerConfig: config).timeout(const Duration(seconds: 10));
    expect(second, isA<PlaybackFailed>());
    expect(((second as PlaybackFailed).error as NativeFailure).code, 'PLAYER_ALREADY_ACTIVE');

    await VideoPlayer.instance.close().timeout(const Duration(seconds: 10));
    final result = await first.timeout(const Duration(seconds: 15));
    expect(result, anyOf(isA<PlaybackCompleted>(), isA<PlaybackCancelled>()));

    // A new session works after the first one ended.
    final third = VideoPlayer.instance.playVideo(playerConfig: config);
    await Future<void>.delayed(const Duration(seconds: 2));
    await VideoPlayer.instance.close();
    expect(await third.timeout(const Duration(seconds: 15)), anyOf(isA<PlaybackCompleted>(), isA<PlaybackCancelled>()));
  });
}
