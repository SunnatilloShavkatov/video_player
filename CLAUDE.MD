# CLAUDE.md - Video Player Plugin Development Guide

A comprehensive Flutter video player plugin with native Android (ExoPlayer), iOS (AVPlayer), and macOS (AVPlayer) implementations.

**Critical Note:** This is a reusable Flutter plugin package (`video_player`), **not** a standalone Flutter app. Native code changes cannot be hot-reloaded and must be tested in the `example/` directory.

- **Package:** `uz.shs.video_player`
- **Current Version:** `3.5.4`
- **Repository:** `https://github.com/SunnatilloShavkatov/video_player`
- **Installation:** Users install via git ref, **not** pub.dev (see `README.md`).

---

## 1. Quick Reference & Commands

### Running Tests
```bash
# Run all unit tests
flutter test

# Run individual critical tests
flutter test test/enum_stability_test.dart  # Platform contract (enum values must NEVER change)
flutter test test/method_channel_test.dart  # MethodChannel contract and result mapping
flutter test test/url_validator_test.dart   # HTTPS enforcement
flutter test test/video_player_test.dart    # Public Dart API behavior

# Run example app tests
cd example && flutter test && cd ..
```

### Building & Running Example App (Testing Native Changes)
Always `flutter clean` when modifying native Swift or Kotlin code — native changes do not hot-reload!

```bash
# iOS (Physical device or simulator)
cd example
flutter clean
cd ios && pod install && cd ..
flutter run -d "iPhone 15 Pro"

# macOS
cd example
flutter clean
cd macos && pod install && cd ..
flutter run -d macos

# Android
cd example
flutter clean
flutter run -d <android_device_or_emulator>
```

---

## 2. Architecture Overview

### Three-Layer Communication Pattern
```
Flutter (Dart)            Method Channel                  Native (Swift/Kotlin)
lib/src/         <--->   "video_player"          <--->   darwin/ (iOS/macOS) or android/src/
```

**Critical Rule:** Any new feature must be implemented across all three layers:
1. `lib/src/video_player_platform_interface.dart` — Define the abstract method contract.
2. `lib/src/video_player_method_channel.dart` — Implement the method channel invocation.
3. Native platforms — Implement in `VideoPlayerPlugin.swift` (Darwin: iOS & macOS) and `VideoPlayerPlugin.kt` (Android).

### Two Player Modes
1. **Full-screen player**:
   - Native activity / view controller launched via `VideoPlayer.instance.playVideo(...)`.
   - Returns a sealed `PlaybackResult`.
   - iOS: Managed via a single active `PlaybackSession` in `VideoPlayerPlugin.swift`.
   - Android: Handled via `VideoPlayerActivity`, holds `resultMethod` in `VideoPlayerPlugin.kt` until finish.
   - macOS: Presented as an overlay via `VideoPlayerOverlayView.swift`.
2. **Embedded player**:
   - `VideoPlayerView` widget for inline rendering (`UiKitView`, `AppKitView`, `AndroidView`).
   - Uses per-view channels: `plugins.video/video_player_view_<id>` (NOT the main `video_player` channel).
   - Controller: `VideoPlayerViewController`.

### Darwin Architecture (iOS & macOS Unification)
Native code for iOS and macOS is unified under the `darwin/` directory (`sharedDarwinSource: true` in `pubspec.yaml`):
- `darwin/video_player.podspec`: Targets iOS (15.0+) and macOS (10.15+).
- `darwin/video_player/Package.swift`: Swift Package Manager setup.
- `darwin/video_player/Sources/video_player/VideoPlayerPlugin.swift`: Plugin registration for Darwin.
- `Common/` & `Assets/`: Shared logic, assets, and models across iOS and macOS.
- `iOS/`: UIKit-specific views (`VideoPlayerViewController.swift`, `VideoViewController.swift`).
- `macOS/`: AppKit-specific views (`VideoPlayerOverlayView.swift`, `VideoPlayerPlatformView.swift`).

---

## 3. Critical Platform Contracts & Invariants

### Time Value Contract (STRICT)
- **Full-screen API time values:** Always in **SECONDS (`int`)** across Dart, Swift, and Kotlin.
  - Example: `lastPositionSeconds: 120` means 2 minutes.
- **Embedded player controller APIs:** Always in **SECONDS (`double`)** (`seekTo`, `getDuration`, `positionStream`, `onDurationReady`).
- **NEVER expose milliseconds across the Flutter/Native platform boundary!**

### Result Handling (Sealed Classes)
Always use Dart 3 pattern matching with `PlaybackResult`:
```dart
final result = await VideoPlayer.instance.playVideo(config);
switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    // Video watched to end or user closed player
  case PlaybackCancelled():
    // User cancelled playback before load completed
  case PlaybackFailed(:final error, :final stackTrace):
    // Playback error occurred
}
```

### URL Validation & Security
- Only **HTTPS** URLs are permitted for streaming (enforced by `validateVideoUrl()` in `lib/src/utils/url_validator.dart`).
- Local Flutter assets use the `playVideoFromAsset: true` flag.

### Android Specifics
- **FLAG_SECURE Timing:** `window.setFlags(FLAG_SECURE, ...)` **must** be called **before** creating `SurfaceView`. Reversing this causes EGL crashes on MediaTek chips.
- **Memory & Buffers:** Keep conservative Media3 ExoPlayer buffer parameters in `PlayerController.kt` to avoid OOM on low-memory devices:
  ```kotlin
  val loadControl = DefaultLoadControl.Builder()
      .setBufferDurationsMs(15000, 30000, 1000, 2000)
  ```

### iOS & macOS Specifics
- **iOS Scene Lifecycle:** Must handle `UISceneDelegate` via `sceneDidBecomeActive` in `VideoPlayerPlugin.swift` to prevent background/foreground crash.
- **Screen Protection:** Available on iOS via `ScreenProtectorKit` (uses secure `UITextField` overlay). Note: only works on physical devices.
- **HLS Quality Parsing:** Handled in `HlsParser.swift`. Only parse `.m3u8` playlists; progressive formats (e.g. mp4) skip parsing.
- **Picture-in-Picture:** Supported on iOS (AVPlayerViewController) and macOS.

---

## 4. Key Files Directory Map

```
video_player/
├── lib/
│   ├── video_player.dart                          # Public export entry point
│   └── src/
│       ├── video_player.dart                      # High-level full-screen API
│       ├── video_player_platform_interface.dart   # Abstract platform interface
│       ├── video_player_method_channel.dart       # Method channel implementation
│       ├── video_player_view.dart                 # Embedded widget & controller
│       ├── models/                                # Configuration and result models
│       │   ├── player_configuration.dart
│       │   └── playback_result.dart
│       └── utils/
│           └── url_validator.dart                 # HTTPS validation
├── darwin/
│   ├── video_player.podspec                       # Shared iOS (15.0+) & macOS (10.15+) podspec
│   └── video_player/Sources/video_player/
│       ├── VideoPlayerPlugin.swift                # Unified Darwin method channel entry
│       ├── Common/                                # Shared models, HLS parser, etc.
│       ├── iOS/                                   # Full-screen & embedded UIKit controllers
│       └── macOS/                                 # Full-screen & embedded AppKit views
├── android/
│   └── src/main/kotlin/uz/shs/video_player/
│       ├── VideoPlayerPlugin.kt                   # Android method channel handler
│       ├── VideoPlayerView.kt                     # Embedded Android platform view
│       ├── activities/VideoPlayerActivity.kt      # Full-screen activity
│       └── player/PlayerController.kt             # Media3 ExoPlayer engine wrapper
└── example/                                       # Example app for testing
```

---

## 5. Coding & Dependency Standards

- **Dart/Flutter:** SDK `>=3.13.0 <4.0.0`, Flutter `>=3.47.0`. Use `analysis_lints: ^1.1.0`.
- **iOS/macOS Native:** Swift 5.0+. Auto Layout with `SnapKit` (~> 5.0) on iOS. iOS min target `15.0`, macOS min target `10.15`.
- **Android Native:** Kotlin. `androidx.media3` (ExoPlayer 1.11.0). Min SDK `26`.
- **Enum Stability:** Never change existing string serialization of enums (`test/enum_stability_test.dart` checks this).

---

## 6. Version Bump Checklist

When preparing a new release:
1. `pubspec.yaml` -> update `version: X.Y.Z`
2. `darwin/video_player.podspec` -> update `s.version = 'X.Y.Z'`
3. `android/build.gradle.kts` -> update `version = "X.Y.Z"`
4. `CHANGELOG.md` -> add release notes
5. Git:
   ```bash
   git commit -m "chore: bump version to X.Y.Z"
   git tag vX.Y.Z
   git push && git push --tags
   ```

---

## 7. Common Pitfalls for AI Assistants
- ❌ **Do not** expose milliseconds across Flutter/Native boundaries (full-screen uses `int` seconds; embedded uses `double` seconds).
- ❌ **Do not** modify enum names or serialized string values.
- ❌ **Do not** send embedded-player work through the main `video_player` channel — use `plugins.video/video_player_view_<id>`.
- ❌ **Do not** publish to pub.dev (users install through git tags/references).
- ❌ **Do not** test native code changes without `flutter clean` first.
- ❌ **Do not** assume simulator supports screen protection (physical device only).
