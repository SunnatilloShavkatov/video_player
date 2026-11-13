import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/native_video_player.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

/// A [VideoPlayerBridge] that records its calls and answers with [result] or [failure].
class FakeVideoPlayerBridge implements VideoPlayerBridge {
  List<int>? result = <int>[0, 0];
  NativeFailure? failure;
  final List<String> playedConfigs = <String>[];
  int closeCount = 0;

  @override
  Future<List<int>?> playVideo(String playerConfigJson) async {
    playedConfigs.add(playerConfigJson);
    final NativeFailure? error = failure;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<void> close() async {
    closeCount++;
    final NativeFailure? error = failure;
    if (error != null) {
      throw error;
    }
  }
}

/// Installs a [NativeVideoPlayer] over a fresh fake and returns the fake.
FakeVideoPlayerBridge installFakeBridge() {
  final FakeVideoPlayerBridge bridge = FakeVideoPlayerBridge();
  VideoPlayerPlatform.instance = NativeVideoPlayer(bridge);
  return bridge;
}
