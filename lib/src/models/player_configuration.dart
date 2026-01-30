/// Configuration model for video playback in full-screen mode.
///
/// This class contains all settings needed to configure the native video player,
/// including video source, UI labels, playback position, and sharing options.
///
/// **IMPORTANT: All time values are in SECONDS (int), matching the native platform contract.**
///
/// **Recommended:** Use factory constructors [PlayerConfiguration.remote] or
/// [PlayerConfiguration.asset] for cleaner, more maintainable code.
///
/// **Example:**
/// ```
/// // Recommended: Use factory constructor
/// final config = PlayerConfiguration.remote(
///   videoUrl: 'https://example.com/video.m3u8',
///   title: 'Sample Video',
///   startPositionSeconds: 120, // Resume at 2 minutes
/// );
///
/// // Advanced: Use full constructor for custom configuration
/// final customConfig = PlayerConfiguration(
///   videoUrl: 'https://example.com/video.m3u8',
///   title: 'Sample Video',
///   qualityText: 'Quality',
///   speedText: 'Speed',
///   autoText: 'Auto',
///   lastPosition: 120, // SECONDS
///   playVideoFromAsset: false,
///   assetPath: '',
///   movieShareLink: 'https://example.com/share',
/// );
/// ```
class PlayerConfiguration {
  /// Creates a player configuration with the specified settings.
  ///
  /// **Advanced Constructor:** For most use cases, prefer [PlayerConfiguration.remote]
  /// or [PlayerConfiguration.asset] factory constructors instead.
  ///
  /// This constructor requires all parameters to be specified. Use this only when
  /// you need full control over all configuration options.
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
    this.enableScreenProtection = true,
  }) : assert(lastPosition >= 0, 'lastPosition must be non-negative');

  /// Creates a configuration for playing a remote video via HTTPS.
  ///
  /// This is the recommended constructor for most use cases. It provides sensible
  /// defaults for all UI labels and playback settings.
  ///
  /// **Parameters:**
  /// - [videoUrl]: The HTTPS URL of the video to play (required)
  /// - [title]: The title displayed in the player UI (required)
  /// - [startPositionSeconds]: Resume position in seconds (default: 0)
  /// - [movieShareLink]: Share URL for the video (default: empty, disables sharing)
  /// - [enableScreenProtection]: Enable screenshot prevention on iOS (default: false)
  /// - [qualityText]: Label for quality selection (default: 'Quality')
  /// - [speedText]: Label for speed selection (default: 'Speed')
  /// - [autoText]: Label for auto quality option (default: 'Auto')
  ///
  /// **Example:**
  /// ```
  /// // Minimal usage
  /// final config = PlayerConfiguration.remote(
  ///   videoUrl: 'https://example.com/video.m3u8',
  ///   title: 'My Video',
  /// );
  ///
  /// // With resume position (in SECONDS)
  /// final resumeConfig = PlayerConfiguration.remote(
  ///   videoUrl: 'https://example.com/video.m3u8',
  ///   title: 'My Video',
  ///   startPositionSeconds: 120, // Resume at 2 minutes
  /// );
  ///
  /// // With sharing enabled
  /// final shareConfig = PlayerConfiguration.remote(
  ///   videoUrl: 'https://example.com/video.m3u8',
  ///   title: 'My Video',
  ///   movieShareLink: 'https://example.com/share/video-123',
  /// );
  ///
  /// // With screen protection (iOS only)
  /// final protectedConfig = PlayerConfiguration.remote(
  ///   videoUrl: 'https://example.com/private-video.m3u8',
  ///   title: 'Confidential Video',
  ///   enableScreenProtection: true,
  /// );
  /// ```
  factory PlayerConfiguration.remote({
    required String videoUrl,
    required String title,
    int startPositionSeconds = 0,
    String movieShareLink = '',
    bool enableScreenProtection = false,
    String qualityText = 'Quality',
    String speedText = 'Speed',
    String autoText = 'Auto',
  }) {
    assert(startPositionSeconds >= 0, 'startPositionSeconds must be non-negative');
    return PlayerConfiguration(
      videoUrl: videoUrl,
      title: title,
      autoText: autoText,
      assetPath: '',
      speedText: speedText,
      qualityText: qualityText,
      lastPosition: startPositionSeconds,
      movieShareLink: movieShareLink,
      playVideoFromAsset: false,
      enableScreenProtection: enableScreenProtection,
    );
  }

  /// Creates a configuration for playing a video from Flutter assets.
  ///
  /// **Note:** Asset playback support may be limited on some platforms.
  /// For production use, prefer [PlayerConfiguration.remote] with HTTPS URLs.
  ///
  /// **Parameters:**
  /// - [assetPath]: Path to the asset file (e.g., 'videos/intro.mp4')
  /// - [title]: The title displayed in the player UI (required)
  /// - [startPositionSeconds]: Resume position in seconds (default: 0)
  /// - [enableScreenProtection]: Enable screenshot prevention on iOS (default: false)
  /// - [qualityText]: Label for quality selection (default: 'Quality')
  /// - [speedText]: Label for speed selection (default: 'Speed')
  /// - [autoText]: Label for auto quality option (default: 'Auto')
  ///
  /// **Example:**
  /// ```
  /// final config = PlayerConfiguration.asset(
  ///   assetPath: 'assets/videos/intro.mp4',
  ///   title: 'Introduction',
  /// );
  /// ```
  ///
  /// **Note:** Make sure the asset is declared in `pubspec.yaml`:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/videos/intro.mp4
  /// ```
  factory PlayerConfiguration.asset({
    required String assetPath,
    required String title,
    int startPositionSeconds = 0,
    bool enableScreenProtection = false,
    String qualityText = 'Quality',
    String speedText = 'Speed',
    String autoText = 'Auto',
  }) {
    assert(startPositionSeconds >= 0, 'startPositionSeconds must be non-negative');
    assert(assetPath.isNotEmpty, 'assetPath cannot be empty');
    return PlayerConfiguration(
      videoUrl: '',
      title: title,
      autoText: autoText,
      assetPath: assetPath,
      speedText: speedText,
      qualityText: qualityText,
      lastPosition: startPositionSeconds,
      movieShareLink: '',
      playVideoFromAsset: true,
      enableScreenProtection: enableScreenProtection,
    );
  }

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
  /// **Unit:** Seconds (int) - matches native platform contract
  ///
  /// **Example:**
  /// ```
  /// lastPosition: 120, // Start at 2 minutes (120 seconds)
  /// ```
  ///
  /// **Range:** `>= 0`
  final int lastPosition;

  /// Label text for the automatic quality option (e.g., "Auto", "Automatic").
  ///
  /// This appears as the default option in the quality selection menu,
  /// indicating adaptive bitrate streaming.
  final String autoText;

  /// Path to asset file when [playVideoFromAsset] is true.
  ///
  /// **Example:**
  /// ```
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
  /// ```
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

  /// Whether to enable screen protection (iOS only).
  ///
  /// When enabled, prevents screenshots and screen recording on iOS devices.
  /// This feature uses layer manipulation which may introduce 10-50ms startup jank.
  ///
  /// **Default:** `false` (disabled for better performance)
  ///
  /// **Platform support:**
  /// - iOS: Full support (screenshot prevention and recording detection)
  /// - Android: No effect (always protected via FLAG_SECURE)
  ///
  /// **Example:**
  /// ```
  /// // Enable screen protection for sensitive content
  /// PlayerConfiguration(
  ///   videoUrl: 'https://example.com/private-video.m3u8',
  ///   enableScreenProtection: true,
  ///   // ... other parameters
  /// );
  /// ```
  ///
  /// **Note:** Layer manipulation on iOS 17+ may be fragile. Only enable
  /// if screen protection is critical for your use case.
  final bool enableScreenProtection;

  /// Converts this configuration to a map for platform channel communication.
  ///
  /// This method is used internally to serialize configuration data
  /// for transmission to native iOS/Android code.
  ///
  /// Platform expects `lastPosition` in seconds (int), which matches our public API.
  Map<String, dynamic> toMap() => {
    'title': title,
    'videoUrl': videoUrl,
    'autoText': autoText,
    'assetPath': assetPath,
    'speedText': speedText,
    'qualityText': qualityText,
    'lastPosition': lastPosition, // Already in seconds
    'movieShareLink': movieShareLink,
    'playVideoFromAsset': playVideoFromAsset,
    'enableScreenProtection': enableScreenProtection,
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
      'movieShareLink: $movieShareLink, '
      'enableScreenProtection: $enableScreenProtection'
      '}';
}
