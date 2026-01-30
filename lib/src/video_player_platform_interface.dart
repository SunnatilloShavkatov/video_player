import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/video_player_method_channel.dart';

abstract class VideoPlayerPlatform extends PlatformInterface {
  /// Constructs a VideoPlayerPlatform.
  VideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPlatform _instance = MethodChannelVideoPlayer();

  /// The default instance of [VideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoPlayer].
  static VideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when
  /// they register themselves.
  static set instance(VideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Plays a video with the given configuration and returns the playback result.
  ///
  /// **Parameters:**
  /// - [playerConfigJsonString]: JSON-encoded player configuration
  ///
  /// **Returns:**
  /// - [PlaybackResult] indicating the outcome of the playback session
  ///
  /// **Implementation Note:**
  /// Platform implementations should translate native responses into [PlaybackResult]:
  /// - Success with position data → [PlaybackCompleted]
  /// - User cancellation → [PlaybackCancelled]
  /// - Errors → [PlaybackFailed]
  Future<PlaybackResult> playVideo({required String playerConfigJsonString});

  /// Closes the currently active video player.
  ///
  /// If no video player is active, this method completes without error.
  Future<void> close();
}
