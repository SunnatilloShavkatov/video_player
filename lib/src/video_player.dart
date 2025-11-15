import 'dart:async';
import 'dart:convert';

import 'package:video_player/src/models/player_configuration.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

export 'package:video_player/src/models/player_configuration.dart';

/// Main video player class that provides video playback and download functionality.
///
/// This class follows the singleton pattern and provides methods for:
/// - Playing videos with custom configurations
/// - Downloading videos for offline playback
/// - Managing download states (pause, resume, remove)
/// - Tracking download progress
final class VideoPlayer {
  const VideoPlayer._();

  /// Returns the singleton instance of VideoPlayer
  static VideoPlayer get instance => _instance;

  static const VideoPlayer _instance = VideoPlayer._();

  /// Helper method to encode configuration to JSON string
  String _encodeConfig(Map<String, dynamic> config) => jsonEncode(config);

  /// Plays a video with the given player configuration.
  ///
  /// Returns a list of integers representing playback time information,
  /// or null if playback fails.
  Future<List<int>?> playVideo({required PlayerConfiguration playerConfig}) {
    final String jsonStringConfig = _encodeConfig(playerConfig.toMap());
    return VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: jsonStringConfig);
  }

  Future<void> close() => VideoPlayerPlatform.instance.close();
}
