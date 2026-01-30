# Video Player Plugin - Development Guide

## Project Overview

A comprehensive Flutter video player plugin with native iOS and Android implementations. This plugin
provides advanced video playback capabilities and iOS screen protection features.

**Package:** uz.shs.video_player
**Version:** 3.0.0
**Repository:** https://github.com/SunnatilloShavkatov/video_player

## Architecture

### Platform Structure

```
video_player/
├── lib/                          # Flutter/Dart code
│   ├── video_player.dart         # Main export file
│   └── src/
│       ├── video_player.dart                    # Core plugin API
│       ├── video_player_platform_interface.dart # Platform interface
│       ├── video_player_method_channel.dart     # Method channel implementation
│       ├── video_player_view.dart               # Embedded player widget
│       └── models/
│           └── player_configuration.dart        # Configuration models
├── ios/                          # iOS native implementation
│   └── Classes/
│       ├── VideoPlayerPlugin.m/h              # Plugin entry point
│       ├── SwiftVideoPlayerPlugin.swift       # Swift plugin implementation
│       ├── ScreenProtectorKit/                # Screen protection
│       ├── PlayerView/                        # Embedded player view
│       └── Player/                            # Full-screen player
└── android/                      # Android native implementation
    └── src/main/kotlin/uz/shs/video_player/
        ├── VideoPlayerPlugin.kt               # Plugin entry point
        ├── VideoPlayerView.kt                 # Embedded player view
        ├── activities/VideoPlayerActivity.kt  # Full-screen player
        ├── models/                            # Data models
        ├── adapters/                          # UI adapters
        └── services/                          # Background services
```

### Key Components

#### Flutter Layer

- **VideoPlayer**: Main API class for streaming video playback
- **VideoPlayerView**: Embedded video player widget for Flutter UI
- **PlayerConfiguration**: Configuration model for video playback
- **VideoPlayerViewController**: Controller for embedded player with playback control and event
  streams

#### iOS Layer

- **VideoPlayerViewController**: Full-screen native player with controls
- **VideoPlayerView**: Embedded UIView for Flutter integration
- **ScreenProtectorKit**: Screenshot and screen recording protection
- **HlsParser**: M3U8 playlist parser for quality detection
- **Note**: Download functionality has been removed as of v2.1.0

#### Android Layer

- **VideoPlayerActivity**: Full-screen player activity
- **VideoPlayerView**: Embedded view for Flutter integration
- **ExoPlayer**: Video playback engine
- **NetworkChangeReceiver**: Download network monitoring

## Recent Changes

### Latest Fixes

- **4b816c6**: Fixed video player crash error
- **ac17665**: Fixed video player crash error (additional fix)
- **3be5ef9**: Fixed EGLSurfaceTexture issue
- **ebab22f**: Added UISceneDelegate migration

## Development Guidelines

### Code Style

**Dart:**

- Follow official Dart style guide
- Use `analysis_lints: ^1.0.5` for linting
- SDK: >=3.10.0 <4.0.0
- Flutter: >=3.38.0

**Swift (iOS):**

- Use Swift 5+ features
- Follow Auto Layout with TinyConstraints/SnapKit
- Minimum iOS version: 15.0+
- Use native iOS frameworks: UIKit, AVFoundation, AVKit

**Kotlin (Android):**

- Follow Kotlin coding conventions
- Use ExoPlayer for video playback
- Target Android API level as defined in build.gradle

### Dependencies

**iOS Third-party:**

- TinyConstraints: Auto Layout DSL
- XLActionController: Custom action sheets
- SnapKit (~> 4.0): Auto Layout
- SDWebImage (~> 5.0): Image loading

**iOS Native:**

- UIKit: UI components
- AVFoundation: Video engine
- AVKit: Advanced playback features
- MediaPlayer: Volume controls

**Flutter:**

- plugin_platform_interface: ^2.1.8

## Common Tasks

### Adding New Features

1. **Update Platform Interface** (`lib/src/video_player_platform_interface.dart`)
    - Define abstract method in platform interface

2. **Implement Method Channel** (`lib/src/video_player_method_channel.dart`)
    - Add method channel call

3. **Update iOS Implementation** (`ios/Classes/SwiftVideoPlayerPlugin.swift`)
    - Handle method call in Swift
    - Implement native iOS functionality

4. **Update Android Implementation** (`android/src/main/kotlin/.../VideoPlayerPlugin.kt`)
    - Handle method call in Kotlin
    - Implement native Android functionality

### Testing

**Manual Testing:**

- Test on physical iOS device (iOS 15.0+)
- Test on physical Android device (API 26+)
- Test video playback from HTTPS URLs
- Test quality selection, speed control, seek functionality
- Test screen protection (iOS only)
- Test lifecycle (open/close 50+ times)

**Example App:**

- Use `example/` directory for testing
- Add test videos in example app

### Debugging

**iOS:**

- Open `ios/video_player.xcworkspace` in Xcode
- Set breakpoints in Swift files
- Check Console for native logs
- Use Instruments for performance profiling

**Android:**

- Open `android/` in Android Studio
- Set breakpoints in Kotlin files
- Use Logcat for native logs
- Use Profiler for performance analysis

**Flutter:**

- Use `flutter run` with `--verbose` flag
- Check method channel communication
- Use Flutter DevTools for widget inspection

## Key Files to Know

### Core Plugin Files

- `lib/src/video_player.dart` - Main plugin API
- `lib/src/video_player_view.dart` - Embedded player widget
- `lib/src/models/player_configuration.dart` - Configuration models

### iOS Implementation

- `ios/Classes/SwiftVideoPlayerPlugin.swift` - Plugin method handler
- `ios/Classes/Player/VideoPlayer/VideoPlayerViewController.swift` - Full-screen player
- `ios/Classes/PlayerView/VideoPlayerView.swift` - Embedded player
- `ios/Classes/ScreenProtectorKit/ScreenProtectorKit.swift` - Screen protection
- `ios/Classes/Player/Utils/HlsParser.swift` - M3U8 parser

### Android Implementation

- `android/src/main/kotlin/.../VideoPlayerPlugin.kt` - Plugin method handler
- `android/src/main/kotlin/.../activities/VideoPlayerActivity.kt` - Full-screen player
- `android/src/main/kotlin/.../VideoPlayerView.kt` - Embedded player

## Known Issues & Workarounds

### iOS Crashes

- **EGLSurfaceTexture issue**: Fixed in commit 3be5ef9
- **UISceneDelegate migration**: Added in commit ebab22f
- Recent crash fixes in commits 4b816c6 and ac17665

### Screen Protection

- Only available on iOS platform
- Requires proper AppDelegate setup
- Screenshot prevention works iOS 13.0+
- Screen recording detection works iOS 11.0+

## Build & Release

### Version Bump

1. Update `version` in `pubspec.yaml`
2. Update `CHANGELOG.md` with changes
3. Commit changes: `git commit -m "chore: bump version to X.Y.Z"`
4. Create tag: `git tag vX.Y.Z`
5. Push: `git push && git push --tags`

### Publishing to pub.dev

```bash
flutter pub publish --dry-run  # Test publishing
flutter pub publish            # Actual publish
```

## Resources

- **Flutter Plugin Development**: https://flutter.dev/docs/development/packages-and-plugins
- **iOS AVFoundation**: https://developer.apple.com/av-foundation/
- **Android ExoPlayer**: https://exoplayer.dev/
- **M3U8 Format**: HLS playlist specification

## Contact & Support

- **Issues**: https://github.com/SunnatilloShavkatov/video_player/issues
- **Homepage**: https://github.com/SunnatilloShavkatov/video_player.git

## Notes for AI Assistants

When working on this project:

- Always test changes on both iOS and Android platforms
- Screen protection features are iOS-only
- M3U8 parsing happens in `HlsParser.swift` for quality detection
- The main branch is `master`
- This is a Flutter plugin, not a standalone app
- Native code changes require rebuilding the Flutter app
