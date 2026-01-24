# Video Player Plugin - Instructions

## Project Overview

Flutter video player plugin with native iOS (AVPlayer) and Android (ExoPlayer) implementations. Provides video playback, offline downloads, and screen protection.

## Features

- **Video Playback**: Full-screen and inline playback with custom controls
- **Offline Downloads**: Background video downloads with progress tracking
- **Screen Protection**: Screenshot and screen recording prevention (iOS)
- **Quality Selection**: Multiple quality options for adaptive streaming
- **Playback Controls**: Play/pause, seek, speed control, fullscreen
- **Picture-in-Picture**: PiP support for both platforms
- **Chromecast**: Casting to external displays

## Platform Differences

### iOS
- Uses AVPlayer/AVFoundation
- Screen protection via secure text field layer
- Screenshot/recording detection via NotificationCenter
- HLS streaming support (.m3u8)

### Android
- Uses ExoPlayer
- DASH/HLS streaming support
- No native screen protection (requires custom implementation)

## Requirements

- Flutter SDK: ≥3.32.0
- Dart: ≥3.8.0
- iOS: ≥15.0
- Android: minSdk 21

## Installation

Add to `pubspec.yaml`:
```yaml
dependencies:
  video_player:
    path: ../
```

### iOS Setup

Add to `ios/Podfile`:
```ruby
platform :ios, '15.0'
```

Add permissions to `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Save videos to library</string>
```

### Android Setup

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Usage

### 1. Video Playback

#### Basic Playback
```dart
import 'package:video_player/video_player.dart';

await VideoPlayer.playVideo(PlayerConfiguration(
  title: 'Sample Video',
  videoUrl: 'https://example.com/video.mp4',
  resizeMode: ResizeMode.fit,
));
```

#### With Subtitle
```dart
await VideoPlayer.playVideo(PlayerConfiguration(
  title: 'Video with Subtitle',
  videoUrl: 'https://example.com/video.mp4',
  subtitleUrl: 'https://example.com/subtitle.vtt',
  resizeMode: ResizeMode.cover,
));
```

#### Platform View (Inline)
```dart
VideoPlayerView(
  url: 'https://example.com/video.mp4',
  resizeMode: ResizeMode.fit,
  onMapViewCreated: (controller) {
    // Controller ready
  },
)
```

### 2. Download Functionality

#### Start Download
```dart
final result = await VideoPlayer.downloadVideo(DownloadVideoRequest(
  title: 'My Video',
  videoUrl: 'https://example.com/video.m3u8',
  quality: VideoQuality.hd720,
));

if (result.success) {
  print('Download ID: ${result.downloadId}');
}
```

#### Monitor Progress
```dart
VideoPlayer.onDownloadProgress.listen((progress) {
  print('${progress.title}: ${progress.percent}%');
  print('Speed: ${progress.downloadSpeed}');
  print('Status: ${progress.status}');
});
```

#### Get Downloaded Videos
```dart
final videos = await VideoPlayer.getDownloadedVideos();
for (var video in videos) {
  print('${video.title}: ${video.filePath}');
}
```

#### Play Downloaded Video
```dart
await VideoPlayer.playDownloadedVideo(
  title: 'My Video',
  filePath: '/path/to/video.mp4',
);
```

#### Delete Download
```dart
await VideoPlayer.deleteDownloadedVideo('My Video');
```

### 3. Screen Protection (iOS)

#### Enable Protection
```dart
await VideoPlayer.playVideo(PlayerConfiguration(
  title: 'Protected Content',
  videoUrl: 'https://example.com/video.mp4',
  enableScreenProtection: true, // Prevents screenshots/recording
));
```

#### Detect Screenshot Attempt
```dart
VideoPlayer.onScreenshotDetected.listen((_) {
  print('Screenshot attempt detected!');
  // Show warning, pause video, etc.
});
```

#### Detect Screen Recording
```dart
VideoPlayer.onScreenRecordingChanged.listen((isRecording) {
  if (isRecording) {
    print('Screen recording started');
    // Pause playback or show warning
  }
});
```

## Configuration Options

### PlayerConfiguration
```dart
PlayerConfiguration({
  required String title,
  required String videoUrl,
  String? subtitleUrl,
  ResizeMode resizeMode = ResizeMode.fit,
  bool autoPlay = true,
  bool showControls = true,
  bool enableScreenProtection = false,
  double startPosition = 0.0,
})
```

### DownloadVideoRequest
```dart
DownloadVideoRequest({
  required String title,
  required String videoUrl,
  VideoQuality quality = VideoQuality.auto,
  Map<String, String>? headers,
})
```

### ResizeMode
- `ResizeMode.fit` - Fit within bounds (letterbox)
- `ResizeMode.cover` - Fill bounds (may crop)
- `ResizeMode.stretch` - Stretch to fill

### VideoQuality
- `VideoQuality.auto` - Adaptive bitrate
- `VideoQuality.hd1080` - 1080p
- `VideoQuality.hd720` - 720p
- `VideoQuality.sd480` - 480p
- `VideoQuality.sd360` - 360p

## API Reference

### Methods

```dart
// Playback
static Future<void> playVideo(PlayerConfiguration config)
static Future<void> playDownloadedVideo(String title, String filePath)

// Downloads
static Future<DownloadResult> downloadVideo(DownloadVideoRequest request)
static Future<List<DownloadedVideo>> getDownloadedVideos()
static Future<void> deleteDownloadedVideo(String title)
static Future<String?> getDownloadedVideoPath(String title)

// Screen Protection (iOS)
static Future<void> configureScreenProtection()
static Future<void> removeScreenProtection()
```

### Streams

```dart
// Download progress
static Stream<DownloadProgress> get onDownloadProgress

// Screen protection events (iOS)
static Stream<void> get onScreenshotDetected
static Stream<bool> get onScreenRecordingChanged
```

### Models

**DownloadProgress**
```dart
{
  String title,
  double percent,
  String downloadSpeed,
  DownloadStatus status,
}
```

**DownloadedVideo**
```dart
{
  String title,
  String filePath,
  int fileSize,
  DateTime downloadDate,
}
```

**DownloadStatus**
- `DownloadStatus.pending`
- `DownloadStatus.downloading`
- `DownloadStatus.completed`
- `DownloadStatus.failed`
- `DownloadStatus.paused`

## Common Patterns

### Error Handling
```dart
try {
  await VideoPlayer.playVideo(config);
} on PlatformException catch (e) {
  print('Error: ${e.code} - ${e.message}');
}
```

### Resource Cleanup
```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _downloadSub;
  
  @override
  void initState() {
    super.initState();
    _downloadSub = VideoPlayer.onDownloadProgress.listen(_onProgress);
  }
  
  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }
}
```

### Download with UI
```dart
VideoPlayer.onDownloadProgress.listen((progress) {
  setState(() {
    _downloadProgress[progress.title] = progress.percent;
  });
});
```

## Troubleshooting

**Video doesn't play:**
- Verify URL is accessible
- Check network permissions
- Ensure video format is supported (mp4, m3u8)

**Download fails:**
- Check storage permissions
- Verify sufficient disk space
- Ensure network connectivity

**Screen protection not working:**
- iOS only feature
- Requires iOS 11+
- Test on physical device (not simulator)

**Memory issues:**
- Dispose StreamSubscriptions
- Don't hold references to large video data
- Use proper lifecycle management

## Example App

See `example/lib/main.dart` for complete implementation:
- Video playback UI
- Download manager
- Offline playback
- Screen protection demo

---

**License:** MIT  
**Platform Support:** iOS 15+, Android API 26+
