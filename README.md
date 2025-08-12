# Video Player

A comprehensive Flutter video player plugin with advanced features including video playback, download capabilities, and screen protection.

## Features

### Video Playback
- **Multi-source support**: Play videos from URLs, assets, and downloaded files
- **Quality selection**: Multiple resolution options with automatic quality detection
- **Playback controls**: Play, pause, seek, and speed control
- **Fullscreen support**: Native fullscreen video playback experience

### Download & Offline Playback
- **Video downloading**: Download videos for offline playback using iOS AVAssetDownloadTask
- **Download management**: Pause, resume, and monitor download progress
- **Storage optimization**: Efficient local storage management
- **Download state tracking**: Real-time download progress and status updates

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
  initialResolution: {'720p': 'https://example.com/video_720p.m3u8'},
  resolutions: {
    '1080p': 'https://example.com/video_1080p.m3u8',
    '720p': 'https://example.com/video_720p.m3u8',
    '480p': 'https://example.com/video_480p.m3u8',
  },
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
  resizeMode: 'fit', // 'fit', 'fill', or 'zoom'
  onCreated: (controller) {
    // Video player created
  },
  onFinished: () {
    // Video finished playing
  },
)
```

## iOS-Specific Features

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

### Download States

The iOS implementation uses the following download states:
- `STATE_QUEUED` (0): Download is queued
- `STATE_STOPPED` (1): Download is stopped
- `STATE_DOWNLOADING` (2): Download in progress
- `STATE_COMPLETED` (3): Download completed
- `STATE_FAILED` (4): Download failed
- `STATE_REMOVING` (5): Download being removed
- `STATE_RESTARTING` (7): Download restarting

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

### DownloadConfiguration
- `url`: Video URL to download
- `title`: Download title/identifier

### MediaItemDownload
- `url`: Download URL
- `percent`: Download progress percentage (0-100)
- `state`: Download state (see states above)
- `downloadedBytes`: Number of bytes downloaded

## Requirements

- **iOS**: 15.0+
- **Flutter**: 3.32.0+
- **Dart**: 3.8.0+

## Dependencies

### iOS
- TinyConstraints
- NVActivityIndicatorView  
- XLActionController
- SnapKit (~> 4.0)
- SDWebImage (~> 5.0)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

