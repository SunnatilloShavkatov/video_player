# Video Player

A comprehensive Flutter video player plugin with advanced features including video playback, download capabilities, and screen protection.

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
  video_player: ^2.0.0
```

### iOS Setup

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

For background downloads, ensure your app supports background modes in `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
    <string>background-fetch</string>
</array>
```

## Usage

### Basic Video Playback

```dart
import 'package:video_player/video_player.dart';

// Play a video from URL
VideoPlayer.playVideo(PlayerConfiguration(
  title: 'Sample Video',
  videoUrl: 'https://example.com/video.mp4',
  qualityText: 'Quality',
  speedText: 'Speed',
  autoText: 'Auto',
  playVideoFromAsset: false,
  assetPath: '',
  lastPosition: 0,
  movieShareLink: 'https://example.com/share',
));
```

### Video Downloads

```dart
// Start download
VideoPlayer.downloadVideo(DownloadConfiguration(
  url: 'https://example.com/video.m3u8',
  title: 'My Video',
));

// Monitor download progress
VideoPlayer.onDownloadProgress.listen((progress) {
  print('Download progress: ${progress.percent}%');
  print('Downloaded bytes: ${progress.downloadedBytes}');
  print('Download state: ${progress.state}');
});

// Pause download
VideoPlayer.pauseDownload(downloadConfig);

// Resume download
VideoPlayer.resumeDownload(downloadConfig);

// Check if video is downloaded
bool isDownloaded = await VideoPlayer.checkIsDownloadedVideo(downloadConfig);
```

### Embedded Video Player

```dart
VideoPlayerView(
  url: 'https://example.com/video.mp4',
  resizeMode: ResizeMode.fit, // ResizeMode.fit, ResizeMode.fill, or ResizeMode.zoom
  onMapViewCreated: (controller) {
    // Video player created, save the controller for later use
    this.controller = controller;
    
    // Listen to position updates
    controller.positionStream.listen((position) {
      print('Current position: $position seconds');
    });
    
    // Get notified when duration is ready
    controller.onDurationReady((duration) {
      print('Video duration: $duration seconds');
    });
  },
)
```

### Playback Controls

```dart
// Play the video
await controller.play();

// Pause the video
await controller.pause();

// Mute audio
await controller.mute();

// Unmute audio
await controller.unmute();

// Get video duration
double duration = await controller.getDuration();

// Seek to a specific position (in seconds)
await controller.seekTo(30.0); // Seek to 30 seconds

// Change video URL
await controller.setUrl(url: 'https://example.com/new-video.mp4');

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

#### Background Downloads
iOS implementation uses `AVAssetDownloadURLSession` for reliable background downloads that continue even when the app is backgrounded.

#### Content Protection
- HLS (HTTP Live Streaming) support with content protection
- DRM-protected content playback (when supported by source)
- Secure storage of downloaded content

## API Reference

### PlayerConfiguration
- `title`: Video title
- `initialResolution`: Initial quality selection
- `resolutions`: Available quality options
- `qualityText`: Text for quality selection button
- `speedText`: Text for speed selection button
- `autoText`: Text for auto quality option
- `playVideoFromAsset`: Whether to play from app assets
- `assetPath`: Asset file path (if playing from assets)
- `lastPosition`: Resume position in seconds
- `movieShareLink`: Share URL for the video

## Requirements

- **iOS**: 15.0+
- **Flutter**: 3.32.0+
- **Dart**: 3.8.0+

## Dependencies

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

