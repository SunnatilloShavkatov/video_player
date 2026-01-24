/// Configuration model for video playback in full-screen mode.
///
/// This class contains all settings needed to configure the native video player,
/// including video source, UI labels, playback position, and sharing options.
///
/// **Example:**
/// ```dart
/// final config = PlayerConfiguration(
///   videoUrl: 'https://example.com/video.m3u8',
///   title: 'Sample Video',
///   qualityText: 'Quality',
///   speedText: 'Speed',
///   autoText: 'Auto',
///   lastPosition: 0,
///   playVideoFromAsset: false,
///   assetPath: '',
///   movieShareLink: 'https://example.com/share',
/// );
/// ```
class PlayerConfiguration {
  /// Creates a player configuration with the specified settings.
  ///
  /// All parameters are required to ensure complete configuration.
  const PlayerConfiguration({
    required this.videoUrl,
    required this.title,
    required this.autoText,
    required this.assetPath,
    required this.speedText,
    required this.qualityText,
    required this.lastPosition,
    required this.movieShareLink,
    required this.playVideoFromAsset,
  });

  /// The title displayed in the video player UI.
  ///
  /// This appears in the player's top bar on both iOS and Android.
  final String title;

  /// The HTTPS URL of the video to play.
  ///
  /// **Supported formats:**
  /// - HLS: `https://example.com/playlist.m3u8`
  /// - MP4: `https://example.com/video.mp4`
  /// - Other progressive download formats
  ///
  /// **Note:** Only HTTPS URLs are supported for security. HTTP URLs will be rejected.
  final String videoUrl;

  /// Label text for the speed selection button (e.g., "Speed", "Playback Speed").
  ///
  /// This text appears in the settings menu for speed control options.
  final String speedText;

  /// The position in seconds where playback should start.
  ///
  /// Use this to resume playback from a previously saved position.
  /// Set to `0` to start from the beginning.
  ///
  /// **Example:**
  /// ```dart
  /// lastPosition: 120, // Start at 2 minutes
  /// ```
  final int lastPosition;

  /// Label text for the automatic quality option (e.g., "Auto", "Automatic").
  ///
  /// This appears as the default option in the quality selection menu,
  /// indicating adaptive bitrate streaming.
  final String autoText;

  /// Path to asset file when [playVideoFromAsset] is true.
  ///
  /// **Example:**
  /// ```dart
  /// assetPath: 'assets/videos/intro.mp4',
  /// playVideoFromAsset: true,
  /// ```
  ///
  /// **Note:** Asset playback is currently not implemented. Use HTTPS URLs instead.
  final String assetPath;

  /// Label text for the quality selection button (e.g., "Quality", "Video Quality").
  ///
  /// This text appears in the settings menu for quality/resolution selection.
  final String qualityText;

  /// Share URL for the video, used when user taps the share button.
  ///
  /// This can be a web page URL or deep link to the video content.
  /// Set to empty string `''` to disable sharing functionality.
  ///
  /// **Example:**
  /// ```dart
  /// movieShareLink: 'https://example.com/videos/123',
  /// ```
  final String movieShareLink;

  /// Whether to play video from app assets instead of URL.
  ///
  /// **Note:** Asset playback is currently not fully implemented.
  /// For production use, set this to `false` and use HTTPS URLs via [videoUrl].
  ///
  /// When `true`, the player will attempt to load video from [assetPath].
  /// When `false`, the player loads video from [videoUrl].
  final bool playVideoFromAsset;

  /// Converts this configuration to a map for platform channel communication.
  ///
  /// This method is used internally to serialize configuration data
  /// for transmission to native iOS/Android code.
  Map<String, dynamic> toMap() => {
    'title': title,
    'videoUrl': videoUrl,
    'autoText': autoText,
    'assetPath': assetPath,
    'speedText': speedText,
    'qualityText': qualityText,
    'lastPosition': lastPosition,
    'movieShareLink': movieShareLink,
    'playVideoFromAsset': playVideoFromAsset,
  };

  @override
  String toString() =>
      'PlayerConfiguration{'
      'videoUrl: $videoUrl, '
      'qualityText: $qualityText, '
      'speedText: $speedText, '
      'lastPosition: $lastPosition, '
      'title: $title, '
      'playVideoFromAsset: $playVideoFromAsset, '
      'assetPath: $assetPath, '
      'autoText: $autoText, '
      'movieShareLink: $movieShareLink'
      '}';
}
