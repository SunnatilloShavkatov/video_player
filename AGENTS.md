# AI Agent Development Guide

## Project Type
Flutter plugin with native iOS (Swift), macOS (Swift), and Android (Kotlin) implementations. This is **not** a Flutter app - it's a reusable package that requires native platform code changes to be tested in the example app.

## Architecture Overview

### Three-Layer Communication Pattern
```
Flutter (Dart)  ←→  Method Channel  ←→  Native (Swift/Kotlin)
lib/src/        ←→  "video_player"  ←→  darwin/ (iOS/macOS) or android/src/
```

**Critical Flow:** All features require implementing across THREE layers:
1. `lib/src/video_player_platform_interface.dart` - Define abstract method
2. `lib/src/video_player_method_channel.dart` - Implement method channel call
3. Native platforms - Handle in `VideoPlayerPlugin.swift` (Darwin iOS & macOS) and `VideoPlayerPlugin.kt` (Android)

### Two Player Modes
1. **Full-screen player** - Native activity/view controller launched via `playVideo()`, returns `PlaybackResult`. iOS keeps a single active `PlaybackSession` in `VideoPlayerPlugin.swift`; Android keeps one pending `resultMethod` in `VideoPlayerPlugin.kt` until `VideoPlayerActivity` finishes; macOS presents an overlay in `VideoPlayerPlugin.swift`.
2. **Embedded player** - `VideoPlayerView` widget for inline playback, uses platform views (`UiKitView`, `AppKitView`, `AndroidView`). Each view instance communicates over `plugins.video/video_player_view_<id>`, not the main `video_player` channel.

## Darwin Architecture (iOS & macOS Unification)
iOS and macOS native code is unified under the `darwin/` directory using standard Flutter Darwin shared source (`sharedDarwinSource: true` in `pubspec.yaml`):
- `darwin/video_player.podspec` targets both iOS (15.0+) and macOS (10.15+).
- `darwin/video_player/Package.swift` manages Swift Package Manager dependencies.
- `darwin/video_player/Sources/video_player/VideoPlayerPlugin.swift` provides plugin registration for iOS and macOS.
- Shared assets and models live in `Common/` and `Assets/`.
- Platform-specific views live in `iOS/` (UIKit) and `macOS/` (AppKit).

## Time Value Contract
**CRITICAL:** Full-screen API time values are **SECONDS (int)** across Dart, Swift, and Kotlin. This is the `PlayerConfiguration` / `PlaybackResult` platform contract from v3.0.0.

Embedded `VideoPlayerViewController` APIs also use **seconds**, but as `double` values (`seekTo`, `getDuration`, `positionStream`, `onDurationReady`). Never expose milliseconds across the Flutter/native boundary.

Example: `lastPositionSeconds: 120` means 2 minutes, not 120 milliseconds.

## Testing Workflow

### After Making Native Changes
```bash
# Navigate to example app
cd example

# iOS - Always clean before testing native changes
flutter clean
cd ios && pod install && cd ..
flutter run -d "iPhone 15 Pro"

# macOS
flutter clean
cd macos && pod install && cd ..
flutter run -d macos

# Android
flutter clean
flutter run -d <android_device>
```

**Why clean?** Native code changes (Swift/Kotlin) aren't hot-reloaded. Must rebuild to see changes.

### Running Tests
```bash
flutter test                    # Run all unit tests
flutter test test/enum_stability_test.dart  # Ensure enum values never change (platform contract)
flutter test test/method_channel_test.dart  # Verify MethodChannel contract and result mapping
flutter test test/url_validator_test.dart   # Verify HTTPS enforcement
flutter test test/video_player_test.dart    # Verify public Dart API behavior
cd example && flutter test      # Run example widget tests
```

**Note:** Real testing requires physical devices. Screen protection only works on physical iOS devices. Test lifecycle by opening/closing player 50+ times.

## Critical Patterns

### Sealed Class for Results (v3.0+)
```dart
// Don't return nullable lists - use sealed PlaybackResult pattern matching
final result = await VideoPlayer.instance.playVideo(...);
switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    // Video watched and closed
  case PlaybackCancelled():
    // User cancelled playback before load
  case PlaybackFailed(:final error, :final stackTrace):
    // Playback error occurred
}
```
See `lib/src/models/playback_result.dart` for the pattern.

### Platform View Registration
- iOS & macOS: `registrar.register(videoViewFactory, withId: "plugins.video/video_player_view")` in `VideoPlayerPlugin.swift`
- Android: `binding.platformViewRegistry.registerViewFactory("plugins.video/video_player_view", ...)` in `VideoPlayerPlugin.kt`

- Per-view commands/events use `plugins.video/video_player_view_<id>` in `lib/src/video_player_view.dart`, `darwin/video_player/Sources/video_player/iOS/VideoPlayerView.swift`, and `android/src/main/kotlin/.../VideoPlayerView.kt`

View ID **must** match across platforms and Dart (`VideoPlayerView` widget).

### URL Validation
Only HTTPS URLs allowed for streaming (security). Use `validateVideoUrl()` from `lib/src/utils/url_validator.dart`. Asset playback uses `playVideoFromAsset: true` flag.

### iOS Scene Lifecycle
iOS 13+ uses `UISceneDelegate`. Plugin handles this in `VideoPlayerPlugin.swift`:
```swift
public func sceneDidBecomeActive(_ scene: UIScene) {
    updateViewController(from: scene)
}
```
Fixes crash from commit `ebab22f`. Don't remove scene lifecycle methods.

### Android ExoPlayer Memory Management
Keep conservative Media3 buffer parameters to prevent OOM on low-memory devices:
```kotlin
val loadControl = DefaultLoadControl.Builder()
    .setBufferDurationsMs(15000, 30000, 1000, 2000)
```

### Android FLAG_SECURE Timing
Must call `window.setFlags(FLAG_SECURE, ...)` **before** creating `SurfaceView`. Reversed order causes EGL crashes on MediaTek chips.

## iOS & macOS Specifics
- **Screen Protection:** iOS uses `ScreenProtectorKit` to prevent screenshots/recording using secure `UITextField` overlay trick
- **HLS Quality Detection:** `HlsParser.swift` parses `.m3u8` playlists to extract quality options. Only run this flow for HLS sources; progressive URLs should skip parsing.
- **Picture-in-Picture:** Supported on iOS (AVPlayerViewController / AVPictureInPictureController) and macOS

## Version Management
```bash
# 1. Update version
# - pubspec.yaml (version: X.Y.Z)
# - darwin/video_player.podspec (s.version = 'X.Y.Z')
# - android/build.gradle.kts (version = "X.Y.Z")
# - CHANGELOG.md (add entry)

# 2. Tag and push
git commit -m "chore: bump version to X.Y.Z"
git tag vX.Y.Z
git push && git push --tags
```

Users install via git ref, not pub.dev (see README.md).

## Common Pitfalls
- **Don't expose milliseconds in Dart or method-channel payloads** - full-screen uses seconds (`int`), embedded view APIs use seconds (`double`)
- **Don't change enum string values** - breaks native platforms (see `test/enum_stability_test.dart`)
- **Don't hot-reload native changes** - must `flutter clean` and rebuild
- **Don't test on simulator only** - screen protection won't work, hardware acceleration differs
- **Don't skip manual lifecycle testing** - crashes often happen after 20+ open/close cycles
- **Don't send embedded-player work through the main `video_player` channel** - use the per-view controller/channel created by `VideoPlayerView`

## Key Files
- `lib/src/video_player.dart` - Full-screen Dart API and `PlaybackResult` entry point
- `lib/src/video_player_platform_interface.dart` - Contract all platforms must implement
- `lib/src/video_player_view.dart` - Embedded widget, per-view channel contract, `ResizeMode` / `PlayerStatus`
- `darwin/video_player/Sources/video_player/VideoPlayerPlugin.swift` - Darwin method channel & platform view handler
- `darwin/video_player/Sources/video_player/iOS/VideoPlayerViewController.swift` - iOS full-screen player
- `darwin/video_player/Sources/video_player/iOS/PlayerObserverManager.swift` - iOS AVPlayer observer lifecycle
- `darwin/video_player/Sources/video_player/iOS/VideoViewController.swift` - iOS embedded player controller
- `darwin/video_player/Sources/video_player/macOS/VideoPlayerOverlayView.swift` - macOS full-screen overlay player
- `darwin/video_player/Sources/video_player/macOS/VideoPlayerPlatformView.swift` - macOS embedded player view
- `android/src/main/kotlin/.../VideoPlayerPlugin.kt` - Android method channel handler  
- `android/src/main/kotlin/.../activities/VideoPlayerActivity.kt` - Android full-screen player
- `android/src/main/kotlin/.../player/PlayerController.kt` - Android Media3 player wrapper
- `lib/src/models/player_configuration.dart` - Configuration model (must serialize to JSON)

## Dependencies
- iOS: SnapKit (~> 5.0) for Auto Layout
- macOS: FlutterMacOS, AVKit, AppKit
- Android: androidx.media3 (ExoPlayer 1.11.0) for playback engine, Gson for config deserialization
- Flutter: plugin_platform_interface ^2.1.8, material_ui ^1.1.0 (example app)

Minimum: iOS 15.0+, macOS 10.15+, Android API 26+, Flutter 3.47.0+, Dart 3.13.0+
