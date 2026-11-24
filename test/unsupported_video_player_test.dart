import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/unsupported_video_player.dart';

void main() {
  test('playVideo fails with UnsupportedError', () async {
    final PlaybackResult result = await UnsupportedVideoPlayer().playVideo(playerConfigJsonString: '{}');

    expect(result, isA<PlaybackFailed>());
    expect((result as PlaybackFailed).error, isA<UnsupportedError>());
  });

  test('close completes without error', () async {
    await expectLater(UnsupportedVideoPlayer().close(), completes);
  });
}
