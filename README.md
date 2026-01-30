# Video Player

A comprehensive Flutter video player plugin with advanced features including video playback and screen protection.

> **⚠️ Version 3.0.0 Breaking Changes**: If you're upgrading from v2.x, please see the [Migration Guide](#migration-from-v2x-to-v30) below.

## Features

### Video Playback
- **Multi-source support**: Play videos from URLs, assets, and downloaded files
- **Quality selection**: Multiple resolution options with automatic quality detection
- **Playback controls**: Play, pause, seek, and speed control
- **Fullscreen support**: Native fullscreen video playback experience

### Screen Protection (iOS)
- **Screenshot prevention**: Prevent screenshots during video playback
- **Screen recording detection**: Detect and handle screen recording attempts
- **Secure playback**: Enhanced content protection for sensitive videos

### Platform Support
- **iOS**: Full native implementation with AVPlayer and AVKit
- **Android**: Native Android implementation
- **Flutter integration**: Seamless integration with Flutter widgets

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

2. Add network security configuration to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note**: For production apps, restrict allowed domains instead of allowing arbitrary loads.

### Android Setup

No additional setup required. The plugin automatically configures ExoPlayer.

## Usage

### Full-Screen Player

Opens a native full-screen video player with built-in controls:

```dart
import 'package:video_player/video_player.dart';

// Play a remote video (recommended approach)
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration.remote(
    videoUrl: 'https://example.com/video.m3u8',
    title: 'Sample Video',
    lastPositionMillis: 30000,  // Resume at 30 seconds (optional)
    movieShareLink: 'https://example.com/share',  // Optional
  ),
);

// Handle the result
switch (result) {
  case PlaybackCompleted(:final lastPositionMillis, :final durationMillis):
    // User watched the video and closed the player
    final seconds = lastPositionMillis ~/ 1000;
    print('User stopped at $seconds seconds');

    // Save progress for next time
    await saveWatchProgress(videoId, lastPositionMillis);

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

```dart
// For advanced use cases with full control
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration(
    videoUrl: 'https://example.com/video.m3u8',
    title: 'Sample Video',
    qualityText: 'Quality',
    speedText: 'Speed',
    autoText: 'Auto',
    lastPositionMillis: 30000,    // Resume position in milliseconds
    playVideoFromAsset: false,
    assetPath: '',
    movieShareLink: 'https://example.com/share',
  ),
);
```

### Embedded Player

Inline video playback within your Flutter UI:

```dart
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

```dart
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

The iOS implementation includes `ScreenProtectorKit` for content protection:

```swift
// In your AppDelegate.swift
import video_player

class AppDelegate: FlutterAppDelegate {
    private var screenProtectorKit: ScreenProtectorKit?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        screenProtectorKit = ScreenProtectorKit(window: window)
        screenProtectorKit?.configurePreventionScreenshot()
        
        // Setup screenshot detection
        screenProtectorKit?.screenshotObserver {
            print("Screenshot detected!")
            // Handle screenshot event
        }
        
        // Setup screen recording detection (iOS 11.0+)
        if #available(iOS 11.0, *) {
            screenProtectorKit?.screenRecordObserver { isCaptured in
                print("Screen recording: \(isCaptured)")
                // Handle screen recording state change
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        screenProtectorKit?.enabledPreventScreenshot()
    }
    
    override func applicationWillResignActive(_ application: UIApplication) {
        screenProtectorKit?.disablePreventScreenshot()
    }
}
```

### Advanced Configuration

#### Video Quality Selection
The plugin automatically sorts video resolutions and provides quality selection UI during playback.

#### Content Protection
- HLS (HTTP Live Streaming) support with content protection
- DRM-protected content playback (when supported by source)

## API Reference

### PlayerConfiguration

#### Factory Constructors (Recommended)

**`PlayerConfiguration.remote()`** - For remote HTTPS videos
```dart
PlayerConfiguration.remote({
  required String videoUrl,           // HTTPS URL
  required String title,              // Video title
  int lastPositionMillis = 0,         // Resume position (milliseconds)
  String movieShareLink = '',         // Share URL (optional)
  bool enableScreenProtection = false,// iOS screenshot prevention
  String qualityText = 'Quality',     // UI label (optional)
  String speedText = 'Speed',         // UI label (optional)
  String autoText = 'Auto',           // UI label (optional)
})
```

**`PlayerConfiguration.asset()`** - For bundled asset videos
```dart
PlayerConfiguration.asset({
  required String assetPath,          // Asset path (e.g., 'videos/intro.mp4')
  required String title,              // Video title
  int lastPositionMillis = 0,         // Resume position (milliseconds)
  bool enableScreenProtection = false,// iOS screenshot prevention
  String qualityText = 'Quality',     // UI label (optional)
  String speedText = 'Speed',         // UI label (optional)
  String autoText = 'Auto',           // UI label (optional)
})
```

#### Properties
- `videoUrl`: HTTPS URL of the video to play
- `title`: Video title displayed in player UI
- `lastPositionMillis`: Resume position in milliseconds (>= 0)
- `movieShareLink`: Share URL for the video (empty to disable sharing)
- `enableScreenProtection`: Enable screenshot prevention (iOS only)
- `qualityText`: Label for quality selection button
- `speedText`: Label for speed selection button
- `autoText`: Label for automatic quality option
- `playVideoFromAsset`: Whether to play from app assets
- `assetPath`: Asset file path (when `playVideoFromAsset` is true)

### PlaybackResult

Sealed class representing the outcome of video playback:

**`PlaybackCompleted`** - User watched and closed the video
```dart
case PlaybackCompleted(:final lastPositionMillis, :final durationMillis):
  // lastPositionMillis: Position when closed (milliseconds)
  // durationMillis: Total video duration (milliseconds)
```

**`PlaybackCancelled`** - User cancelled before video loaded
```dart
case PlaybackCancelled():
  // User dismissed player early
```

**`PlaybackFailed`** - Playback encountered an error
```dart
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

Version 3.0.0 introduces breaking changes focused on API clarity and type safety. Here's how to migrate:

### 1. Update PlaybackResult Handling

**Before (v2.x):**
```dart
final result = await VideoPlayer.instance.playVideo(playerConfig: config);
if (result != null) {
  final position = result[0];  // Unclear units
  final duration = result[1];
  await saveProgress(position);
}
```

**After (v3.0):**
```dart
final result = await VideoPlayer.instance.playVideo(playerConfig: config);

switch (result) {
  case PlaybackCompleted(:final lastPositionMillis, :final durationMillis):
    await saveProgress(lastPositionMillis);  // Clear: milliseconds

  case PlaybackCancelled():
    // Handle cancellation

  case PlaybackFailed(:final error):
    // Handle error
    print('Error: $error');
}
```

### 2. Use Factory Constructors

**Before (v2.x):**
```dart
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
```dart
PlayerConfiguration.remote(
  videoUrl: 'https://example.com/video.m3u8',
  title: 'My Video',
  lastPositionMillis: 120000,  // Milliseconds (clear)
)
```

### 3. Update Time Units

All time values are now in **milliseconds** instead of seconds:

**Before (v2.x):**
```dart
lastPosition: 120,  // 2 minutes in seconds
```

**After (v3.0):**
```dart
lastPositionMillis: 120000,  // 2 minutes in milliseconds
```

**Conversion:**
```dart
// Old seconds → new milliseconds
final milliseconds = oldSeconds * 1000;

// New milliseconds → seconds for display
final seconds = lastPositionMillis ~/ 1000;
```

### 4. Update Error Handling

**Before (v2.x):**
```dart
try {
  final result = await VideoPlayer.instance.playVideo(playerConfig: config);
} catch (e) {
  // Some errors thrown, some returned as null
}
```

**After (v3.0):**
```dart
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
- [ ] Convert `lastPosition` from seconds to `lastPositionMillis` in milliseconds (multiply by 1000)
- [ ] Update error handling to distinguish validation vs runtime errors
- [ ] Test video playback and resume functionality
- [ ] Verify position tracking accuracy

**Estimated migration time:** 15-60 minutes depending on app size.

## Requirements

- **iOS**: 15.0+
- **Android**: 26+
- **Flutter**: 3.32.0+
- **Dart**: 3.8.0+

## Dependencies. 

### iOS

**Third-party Libraries:**
- **TinyConstraints**: Auto Layout DSL for Swift
- **XLActionController**: Customizable action sheets
- **SnapKit (~> 4.0)**: Swift Auto Layout DSL
- **SDWebImage (~> 5.0)**: Image loading and caching

**Native iOS Frameworks:**
- **UIKit**: For native UI components (UIActivityIndicatorView, etc.)
- **AVFoundation**: Core video playback engine
- **AVKit**: Advanced video playback features and Picture-in-Picture
- **MediaPlayer**: Volume controls and media information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

