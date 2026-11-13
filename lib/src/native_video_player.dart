import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/utils/log_message.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

/// [VideoPlayerPlatform] over a [VideoPlayerBridge]: turns what native reports into a [PlaybackResult].
class NativeVideoPlayer extends VideoPlayerPlatform {
  new(this._bridge);

  final VideoPlayerBridge _bridge;

  @override
  Future<PlaybackResult> playVideo({required String playerConfigJsonString}) async {
    try {
      final List<int>? result = await _bridge.playVideo(playerConfigJsonString);
      if (result == null) {
        // null response indicates user cancelled playback
        return const PlaybackCancelled();
      }
      if (result.length != 2) {
        return PlaybackFailed(error: 'Invalid platform response: expected 2 elements, got ${result.length}');
      }
      // Native already reports SECONDS.
      return PlaybackCompleted(lastPositionSeconds: result[0], durationSeconds: result[1]);
    } catch (error, stackTrace) {
      logMessage('playVideo failed', error: error, stackTrace: stackTrace);
      return PlaybackFailed(error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> close() async {
    try {
      await _bridge.close();
    } catch (error, stackTrace) {
      logMessage('close failed', error: error, stackTrace: stackTrace);
    }
  }
}
