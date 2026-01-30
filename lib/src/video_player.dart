import 'dart:async';
import 'dart:convert';

import 'package:video_player/src/models/playback_result.dart';
import 'package:video_player/src/models/player_configuration.dart';
import 'package:video_player/src/utils/url_validator.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

export 'package:video_player/src/models/playback_result.dart';
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
/// ```
/// final result = await VideoPlayer.instance.playVideo(
///   playerConfig: PlayerConfiguration.remote(
///     videoUrl: 'https://example.com/video.m3u8',
///     title: 'Sample Video',
///   ),
/// );
///
/// switch (result) {
///   case PlaybackCompleted(:final lastPositionMillis, :final durationMillis):
///     print('Video closed at ${lastPositionMillis}ms of ${durationMillis}ms');
///   case PlaybackCancelled():
///     print('User cancelled');
///   case PlaybackFailed(:final error):
///     print('Error: $error');
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
  /// speed control, and other features. Returns a [PlaybackResult] indicating the outcome.
  ///
  /// **Parameters:**
  /// - [playerConfig]: Configuration object containing video URL, title, UI labels, and playback settings.
  ///
  /// **Returns:**
  /// - [PlaybackCompleted] when user watches and closes the video normally
  /// - [PlaybackCancelled] when user cancels before video loads
  /// - [PlaybackFailed] when playback encounters an error
  ///
  /// **Throws:**
  /// - [ArgumentError] if the video URL is not a valid HTTPS URL.
  ///
  /// **Platform-Specific Behavior:**
  /// - **iOS**: Uses AVPlayer with native controls, supports Picture-in-Picture
  /// - **Android**: Uses ExoPlayer with custom controls, supports Picture-in-Picture on Android 8.0+
  ///
  /// **Example:**
  /// ```
  /// final result = await VideoPlayer.instance.playVideo(
  ///   playerConfig: PlayerConfiguration.remote(
  ///     videoUrl: 'https://example.com/video.m3u8',
  ///     title: 'My Video',
  ///   ),
  /// );
  ///
  /// switch (result) {
  ///   case PlaybackCompleted(:final lastPositionMillis, :final durationMillis):
  ///     final seconds = lastPositionMillis ~/ 1000;
  ///     print('User stopped at $seconds seconds');
  ///     await saveWatchProgress(videoId, lastPositionMillis);
  ///
  ///   case PlaybackCancelled():
  ///     print('User cancelled playback');
  ///
  ///   case PlaybackFailed(:final error):
  ///     print('Playback failed: $error');
  ///     showErrorDialog('Unable to play video');
  /// }
  /// ```
  Future<PlaybackResult> playVideo({required PlayerConfiguration playerConfig}) {
    if (UrlValidator.instance.isNotValidHttpsUrl(playerConfig.videoUrl)) {
      throw ArgumentError.value(
        playerConfig.videoUrl,
        'playerConfig.videoUrl',
        'Invalid URL format. Must be HTTPS URL',
      );
    }
    final String jsonStringConfig = _encodeConfig(playerConfig.toMap());
    return VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: jsonStringConfig);
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
  /// ```
  /// // Close the video player programmatically
  /// await VideoPlayer.instance.close();
  /// ```
  ///
  /// **Note:** This is typically not needed as users can close the player using
  /// the built-in close button. Use this for programmatic control only.
  Future<void> close() => VideoPlayerPlatform.instance.close();
}
