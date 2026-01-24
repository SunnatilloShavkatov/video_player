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

final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration(
    videoUrl: 'https://example.com/video.m3u8',
    title: 'Sample Video',
    qualityText: 'Quality',
    speedText: 'Speed',
    autoText: 'Auto',
    lastPosition: 0,              // Resume position in seconds
    playVideoFromAsset: false,
    assetPath: '',
    movieShareLink: 'https://example.com/share',
  ),
);

// Handle result when user closes player
if (result != null) {
  final position = result[0];  // Last position in seconds
  final duration = result[1];  // Total duration in seconds
  print('Stopped at $position of $duration seconds');
}
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

