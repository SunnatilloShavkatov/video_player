import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

/// [VideoPlayerPlatform] for platforms without a native player (web, Windows, Linux, Fuchsia): playback fails with
/// an [UnsupportedError] and [close] does nothing.
class UnsupportedVideoPlayer extends VideoPlayerPlatform {
  @override
  Future<PlaybackResult> playVideo({required String playerConfigJsonString}) async =>
      PlaybackFailed(error: UnsupportedError('video_player supports only Android, iOS and macOS'));

  @override
  Future<void> close() async {}
}
