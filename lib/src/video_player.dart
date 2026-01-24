import 'dart:async';
import 'dart:convert';

import 'package:video_player/src/models/player_configuration.dart';
import 'package:video_player/src/utils/url_validator.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

export 'package:video_player/src/models/player_configuration.dart';

/// Main video player class that provides streaming video playback functionality.
///
/// This class follows the singleton pattern and provides methods for:
/// - Playing videos from HTTPS URLs with custom configurations
/// - Closing the active video player
///
/// **Platform Support:**
/// - iOS 15.0+
/// - Android API 26+
///
/// **Supported Video Formats:**
/// - HLS (HTTP Live Streaming) - `.m3u8` playlists
/// - MP4 and other progressive download formats
/// - Adaptive bitrate streaming
///
/// **Example:**
/// ```dart
/// final result = await VideoPlayer.instance.playVideo(
///   playerConfig: PlayerConfiguration(
///     videoUrl: 'https://example.com/video.m3u8',
///     title: 'Sample Video',
///     qualityText: 'Quality',
///     speedText: 'Speed',
///     autoText: 'Auto',
///     lastPosition: 0,
///     playVideoFromAsset: false,
///     assetPath: '',
///     movieShareLink: '',
///   ),
/// );
/// if (result != null) {
///   print('Video closed at ${result[0]}s of ${result[1]}s total duration');
/// }
/// ```
final class VideoPlayer {
  const VideoPlayer._();

  /// Returns the singleton instance of [VideoPlayer].
  ///
  /// Use this instance to access all video player functionality.
  static VideoPlayer get instance => _instance;

  static const VideoPlayer _instance = VideoPlayer._();

  /// Helper method to encode configuration to JSON string for native platform communication.
  String _encodeConfig(Map<String, dynamic> config) => jsonEncode(config);

  /// Plays a video in full-screen mode with the given configuration.
  ///
  /// Opens a native full-screen video player with playback controls, quality selection,
  /// speed control, and other features.
  ///
  /// **Parameters:**
  /// - [playerConfig]: Configuration object containing video URL, title, UI labels, and playback settings.
  ///
  /// **Returns:**
  /// - `List<int>?` containing `[currentPosition, totalDuration]` in seconds when the player is closed by the user.
  /// - `null` if playback fails to start or is cancelled before the video loads.
  ///
  /// **Return Value Details:**
  /// - `result[0]`: Last playback position in seconds when user closed the player
  /// - `result[1]`: Total video duration in seconds
  ///
  /// **Throws:**
  /// - [Exception] if the video URL is not a valid HTTPS URL.
  /// - Platform-specific exceptions if native player initialization fails.
  ///
  /// **Platform-Specific Behavior:**
  /// - **iOS**: Uses AVPlayer with native controls, supports Picture-in-Picture
  /// - **Android**: Uses ExoPlayer with custom controls, supports Picture-in-Picture on Android 8.0+
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   final result = await VideoPlayer.instance.playVideo(
  ///     playerConfig: PlayerConfiguration(
  ///       videoUrl: 'https://example.com/video.m3u8',
  ///       title: 'My Video',
  ///       qualityText: 'Quality',
  ///       speedText: 'Speed',
  ///       autoText: 'Auto',
  ///       lastPosition: 30, // Resume from 30 seconds
  ///       playVideoFromAsset: false,
  ///       assetPath: '',
  ///       movieShareLink: 'https://example.com/share',
  ///     ),
  ///   );
  ///
  ///   if (result != null) {
  ///     final position = result[0];
  ///     final duration = result[1];
  ///     print('User stopped at $position seconds of $duration total');
  ///   }
  /// } catch (e) {
  ///   print('Failed to play video: $e');
  /// }
  /// ```
  Future<List<int>?> playVideo({required PlayerConfiguration playerConfig}) {
    if (UrlValidator.instance.isNotValidHttpsUrl(playerConfig.videoUrl)) {
      throw Exception('Invalid URL format. Must be HTTPS URL');
    } else {
      final String jsonStringConfig = _encodeConfig(playerConfig.toMap());
      return VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: jsonStringConfig);
    }
  }

  /// Closes the currently active full-screen video player.
  ///
  /// This method programmatically dismisses the video player if one is currently open.
  /// If no video player is active, this method completes without error.
  ///
  /// **Platform-Specific Behavior:**
  /// - **iOS**: Dismisses the presented VideoPlayerViewController
  /// - **Android**: Finishes the VideoPlayerActivity
  ///
  /// **Example:**
  /// ```dart
  /// // Close the video player programmatically
  /// await VideoPlayer.instance.close();
  /// ```
  ///
  /// **Note:** This is typically not needed as users can close the player using
  /// the built-in close button. Use this for programmatic control only.
  Future<void> close() => VideoPlayerPlatform.instance.close();
}
