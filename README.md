# Video Player

A comprehensive Flutter video player plugin with advanced features including video playback and
screen protection.

> **⚠️ Version 3.0.0 Breaking Changes**: If you're upgrading from v2.x, please see
> the [Migration Guide](#migration-from-v2x-to-v30) below.

## Features

### Video Playback

- **Multi-source support**: Play videos from HTTPS URLs and Flutter assets
- **Quality selection**: Multiple resolution options with automatic quality detection
- **Playback controls**: Play, pause, seek, and speed control
- **Fullscreen support**: Native fullscreen video playback experience
- **Android reconnect retry**: Full-screen remote playback on Android retries after temporary network loss and shows clearer offline error messaging

### Screen Protection (iOS)

- **Screenshot prevention**: Prevent screenshots during video playback
- **Screen recording detection**: Detect and handle screen recording attempts
- **Secure playback**: Enhanced content protection for sensitive videos

### Platform Support

- **iOS**: Full native implementation with AVPlayer and AVKit
- **Android**: Native Android implementation
- **Flutter integration**: Seamless integration with Flutter widgets

### Android Error Messages

The fullscreen Android player shows localized retry messages for playback failures:

- **English**
- **Uzbek**
- **Russian**

When the device is offline, users see a dedicated no-internet message instead of a generic playback error.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  video_player:
    git:
      url: https://github.com/SunnatilloShavkatov/video_player.git
      ref: master
```

### iOS Setup

1. Set minimum iOS version to 15.0 in `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

2. Use **HTTPS** URLs for remote playback.

This plugin validates remote URLs and rejects non-HTTPS streams. No extra ATS override is required
for normal HTTPS playback.

### Android Setup

Update minimum SDK version to 26 in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 26  // Required by video_player
    }
}
```

The plugin automatically configures ExoPlayer - no other setup required.

## Usage

### Full-Screen Player

Opens a native full-screen video player with built-in controls:

```
import 'package:video_player/video_player.dart';

// Play a remote video (recommended approach)
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration.remote(
    videoUrl: 'https://example.com/video.m3u8',
    title: 'Sample Video',
    startPositionSeconds: 30,  // Resume at 30 seconds (optional)
    movieShareLink: 'https://example.com/share',  // Optional
  ),
);

// Handle the result
switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    // User watched the video and closed the player
    print('User stopped at $lastPositionSeconds seconds');

    // Save progress for next time
    await saveWatchProgress(videoId, lastPositionSeconds);

  case PlaybackCancelled():
    // User cancelled before video loaded
    print('User cancelled playback');

  case PlaybackFailed(:final error, :final stackTrace):
    // Playback failed
    print('Playback error: $error');
    showErrorDialog('Unable to play video. Please try again.');
}
```

**Legacy approach (still supported):**

```
// For advanced use cases with full control
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration(
    videoUrl: 'https://example.com/video.m3u8',
    title: 'Sample Video',
    qualityText: 'Quality',
    speedText: 'Speed',
    autoText: 'Auto',
    lastPosition: 30,    // Resume position in seconds
    playVideoFromAsset: false,
    assetPath: '',
    movieShareLink: 'https://example.com/share',
  ),
);
```

### Embedded Player

Inline video playback within your Flutter UI:

```
class VideoWidget extends StatefulWidget {
  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerViewController _controller;

  @override
  Widget build(BuildContext context) {
    return VideoPlayerView(
      url: 'https://example.com/video.m3u8',
      resizeMode: ResizeMode.fit,
      onVideoViewCreated: (controller) {
        _controller = controller;
        
        // Start playback
        controller.play();
        
        // Monitor position
        controller.positionStream.listen((position) {
          print('Position: $position seconds');
        });
        
        // Monitor status
        controller.statusStream.listen((status) {
          if (status == PlayerStatus.ended) {
            print('Video finished');
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose!
    super.dispose();
  }
}
```

### Playback Control API

```
// Playback control
await controller.play();
await controller.pause();

// Audio control
await controller.mute();
await controller.unmute();

// Seeking
await controller.seekTo(seconds: 30.0);

// Get duration
final duration = await controller.getDuration();

// Change video
await controller.setUrl(url: 'https://example.com/other.m3u8');

// Load video from assets
await controller.setAssets(assets: 'assets/videos/my_video.mp4');
```

## iOS-Specific Features

### Native UI Components

The iOS implementation uses native iOS components for optimal performance:

- **UIActivityIndicatorView**: Native loading indicators for video buffering and loading states
- **AVPlayer & AVKit**: Core video playback functionality
- **Native gestures**: Swipe for volume/brightness, tap to play/pause, double-tap to seek

### Screen Protection

The fullscreen iOS player uses `ScreenProtectorKit` internally.

> **Current behavior:** there is no public Dart toggle for screen protection in the current API.
> The plugin manages the native protection layer itself during fullscreen playback.

### Advanced Configuration

#### Video Quality Selection

The plugin automatically sorts video resolutions and provides quality selection UI during playback.

#### Content Protection

- HLS (HTTP Live Streaming) support with content protection

## API Reference

### PlayerConfiguration

#### Factory Constructors (Recommended)

**`PlayerConfiguration.remote()`** - For remote HTTPS videos

```
PlayerConfiguration.remote({
  required String videoUrl,           // HTTPS URL
  required String title,              // Video title
  int startPositionSeconds = 0,       // Resume position (seconds)
  String movieShareLink = '',         // Share URL (optional)
  String qualityText = 'Quality',     // UI label (optional)
  String speedText = 'Speed',         // UI label (optional)
  String autoText = 'Auto',           // UI label (optional)
})
```

**`PlayerConfiguration.asset()`** - For bundled asset videos

```
PlayerConfiguration.asset({
  required String assetPath,          // Asset path (e.g., 'videos/intro.mp4')
  required String title,              // Video title
  int startPositionSeconds = 0,       // Resume position (seconds)
  String qualityText = 'Quality',     // UI label (optional)
  String speedText = 'Speed',         // UI label (optional)
  String autoText = 'Auto',           // UI label (optional)
})
```

#### Properties

- `videoUrl`: HTTPS URL of the video to play
- `title`: Video title displayed in player UI
- `lastPosition`: Resume position in seconds (>= 0)
- `movieShareLink`: Share URL for the video (empty to disable sharing)
- `qualityText`: Label for quality selection button
- `speedText`: Label for speed selection button
- `autoText`: Label for automatic quality option
- `playVideoFromAsset`: Whether to play from app assets
- `assetPath`: Asset file path (when `playVideoFromAsset` is true)

### PlaybackResult

Sealed class representing the outcome of video playback:

**`PlaybackCompleted`** - User watched and closed the video

```
case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
  // lastPositionSeconds: Position when closed (seconds)
  // durationSeconds: Total video duration (seconds)
```

**`PlaybackCancelled`** - User cancelled before video loaded

```
case PlaybackCancelled():
  // User dismissed player early
```

**`PlaybackFailed`** - Playback encountered an error

```
case PlaybackFailed(:final error, :final stackTrace):
  // error: Error object
  // stackTrace: Optional stack trace for debugging
```

### VideoPlayerViewController

Controller for embedded player view:

**Playback Control:**

- `play()` - Start/resume playback
- `pause()` - Pause playback
- `seekTo({required double seconds})` - Seek to position

**Audio Control:**

- `mute()` - Mute audio
- `unmute()` - Unmute audio

**Video Source:**

- `setUrl({required String url, ResizeMode resizeMode})` - Change video URL
- `setAssets({required String assets, ResizeMode resizeMode})` - Load asset video

**Information:**

- `getDuration()` - Get video duration in seconds
- `positionStream` - Stream of position updates (seconds)
- `statusStream` - Stream of [PlayerStatus] changes

**Lifecycle:**

- `dispose()` - Clean up resources (always call in widget dispose)

### Enums

**`ResizeMode`** - Video scaling mode

- `fit` - Fit video within view (letterbox if needed)
- `fill` - Fill entire view (crop if needed)
- `zoom` - Zoom to fill while maintaining aspect ratio

**`PlayerStatus`** - Player state

- `idle` - No video loaded
- `buffering` - Loading video data
- `ready` - Ready to play
- `playing` - Currently playing
- `paused` - Paused
- `ended` - Playback finished
- `error` - Error occurred

## Migration from v2.x to v3.0

Version 3.0.0 introduces breaking changes focused on API clarity and type safety. Here's how to
migrate:

### 1. Update PlaybackResult Handling

**Before (v2.x):**

```
final result = await VideoPlayer.instance.playVideo(playerConfig: config);
if (result != null) {
  final position = result[0];  // Unclear units
  final duration = result[1];
  await saveProgress(position);
}
```

**After (v3.0):**

```
final result = await VideoPlayer.instance.playVideo(playerConfig: config);

switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    await saveProgress(lastPositionSeconds);  // Clear: seconds

  case PlaybackCancelled():
    // Handle cancellation

  case PlaybackFailed(:final error):
    // Handle error
    print('Error: $error');
}
```

### 2. Use Factory Constructors

**Before (v2.x):**

```
PlayerConfiguration(
  videoUrl: 'https://example.com/video.m3u8',
  title: 'My Video',
  qualityText: 'Quality',     // Boilerplate
  speedText: 'Speed',         // Boilerplate
  autoText: 'Auto',           // Boilerplate
  lastPosition: 120,          // Seconds (unclear)
  playVideoFromAsset: false,
  assetPath: '',
  movieShareLink: '',
)
```

**After (v3.0):**

```
PlayerConfiguration.remote(
  videoUrl: 'https://example.com/video.m3u8',
  title: 'My Video',
  startPositionSeconds: 120,  // Seconds (clear)
)
```

### 3. Time Units Are Consistent

All time values remain in **seconds (int)** for consistency:

**Before (v2.x):**

```
lastPosition: 120,  // 2 minutes in seconds (unclear)
```

**After (v3.0):**

```
startPositionSeconds: 120,  // 2 minutes in seconds (clear parameter name)
```

**No conversion needed** - the unit is the same, but now explicit in the parameter name.

### 4. Update Error Handling

**Before (v2.x):**

```
try {
  final result = await VideoPlayer.instance.playVideo(playerConfig: config);
} catch (e) {
  // Some errors thrown, some returned as null
}
```

**After (v3.0):**

```
try {
  final result = await VideoPlayer.instance.playVideo(playerConfig: config);

  if (result is PlaybackFailed) {
    // Handle playback/runtime errors
  }
} on ArgumentError catch (e) {
  // Handle validation errors (invalid URL, bad config)
}
```

### 5. Quick Migration Checklist

- [ ] Replace `List<int>?` result handling with `PlaybackResult` pattern matching
- [ ] Update `PlayerConfiguration` to use `.remote()` or `.asset()` factories
- [ ] Rename parameter from `lastPosition` to `startPositionSeconds` for clarity (value stays in
  seconds)
- [ ] Update error handling to distinguish validation vs runtime errors
- [ ] Test video playback and resume functionality
- [ ] Verify position tracking accuracy

**Estimated migration time:** 15-60 minutes depending on app size.

## Requirements

- **iOS**: 15.0+
- **Android**: 26+
- **Flutter**: 3.41.0+
- **Dart**: 3.11.0+

## Dependencies.

### iOS

**Third-party Libraries:**

- **SnapKit (~> 4.0)**: Swift Auto Layout DSL

**Native iOS Frameworks:**

- **UIKit**: For native UI components (UIActivityIndicatorView, etc.)
- **AVFoundation**: Core video playback engine
- **AVKit**: Advanced video playback features and Picture-in-Picture
- **MediaPlayer**: Volume controls and media information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

