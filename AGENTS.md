# AI Agent Development Guide — Video Player Plugin

## 1. Project Type & Core Invariants
Flutter plugin with native iOS (Swift), macOS (Swift), and Android (Kotlin) implementations.
- **Three-Layer Sync:** All player features span 3 layers:
  1. `lib/src/video_player_platform_interface.dart` (interface)
  2. `lib/src/video_player_method_channel.dart` (channel)
  3. `darwin/.../VideoPlayerPlugin.swift` & `android/.../VideoPlayerPlugin.kt` (native)
- **Time Value Contract (STRICT):**
  - Full-screen API: **SECONDS (`int`)**. Never milliseconds.
  - Embedded view API: **SECONDS (`double`)** (`seekTo`, `getDuration`, `positionStream`).
  - Milliseconds across Flutter/native boundaries is a breaking error.
- **File Size Rule:** Native source files must stay under ~500 lines (`PlayerView.swift` under ~450). When logic grows, extract into a subcomponent instead of growing the file.
- **Security & URLs:** HTTPS only for streaming (`validateVideoUrl()`). Assets use `playVideoFromAsset: true`.

---

## 2. Zero-Hop Feature Dispatch Matrix
Do not search or explore the codebase blindly. Dispatch directly to the component that owns the logic:

| Feature / Concern | iOS (UIKit) | macOS (AppKit) | Android (Media3) | Dart Layer |
|---|---|---|---|---|
| **Buttons, Slider, Layout** | `iOS/Player/PlayerOverlayView.swift` | `macOS/PlayerControlsView.swift` | `activity_video_player.xml` | `video_player_view.dart` |
| **Play, Pause, Seek, Rate** | `iOS/Player/PlayerController.swift` | `macOS/VideoPlayerOverlayView.swift` | `player/PlayerController.kt` | `video_player_method_channel.dart` |
| **KVO, Time, Notifications** | `iOS/Player/PlayerObserverManager.swift` | `macOS/VideoPlayerOverlayView.swift` | `player/PlayerController.kt` | `video_player_view_controller.dart` |
| **Gestures (Tap/Pan/Pinch)** | `iOS/Player/PlayerGestureHandler.swift` | `macOS/VideoPlayerOverlayView.swift` | `player/PlayerGestureHandler.kt` | - |
| **Controls Visibility & Spinner**| `iOS/Player/PlayerControlsCoordinator.swift` | `macOS/PlayerControlsView.swift` | `player/PlayerControlsCoordinator.kt` | - |
| **Stall / Network / Audio Recovery**| `iOS/Player/PlaybackRecoveryManager.swift` | - | `player/PlaybackRecoveryManager.kt` | - |
| **Subtitles (WebVTT)** | `iOS/Subtitles/SubtitleController.swift` | - | `subtitles/SubtitleController.kt` | `video_player_view.dart` |
| **Sheets, PiP, Screen Protect** | `iOS/FullScreen/VideoPlayerViewController.swift`| - | `fullscreen/VideoPlayerActivity.kt` | `video_player.dart` |
| **Embedded Platform View** | `iOS/Embedded/VideoViewController.swift` + `Common/EmbeddedPlayerObserver.swift` (KVO, position; shared) | `macOS/VideoPlayerPlatformView.swift` + `Common/EmbeddedPlayerObserver.swift` | `embedded/VideoPlayerView.kt` | `video_player_view.dart` (widget) + `video_player_view_controller.dart` (commands, streams) |
| **Shared Darwin Logic** | `Common/` (Strictly NO UIKit/AppKit imports) | `Common/` | - | - |

---

## 3. Fast-Path Decision & Execution Rules

1. **No Blind Exploration:** Use the Dispatch Matrix above to open the exact file. Never search repository-wide when the owning file is in the table.
2. **Selective File Reading (Token Conservation):**
   - For files > 300 lines (`VideoPlayerActivity.kt`, `VideoPlayerViewController.swift`, `video_player_view_controller.dart`), read only target line ranges (`StartLine`/`EndLine`).
   - Never read `CHANGELOG.md`, `INSTRUCTIONS.md`, `API_CLARIFICATION.md`, `pubspec.lock`, or generated files in full. Use `rg -n` for lookups.
3. **No Builds Without User Consent:**
   - Never run `flutter build`, `flutter run`, `pod install`, or `./gradlew`.
   - For Swift compile check: `bash .claude/skills/darwin-typecheck/scripts/typecheck.sh`
   - For Android compile check: `bash .claude/skills/android-typecheck/scripts/typecheck.sh`
   - For Dart unit tests: `flutter test -r failures-only [test/<file>_test.dart]`
4. **iOS & macOS Darwin Rules:**
   - Podspec globs `Common/**` + `iOS/**` for iOS, and `Common/**` + `macOS/**` for macOS.
   - Wrap platform files in `#if os(iOS)` or `#if os(macOS)`.
   - Never put UIKit/AppKit/Cocoa imports in `Common/`.
5. **Android Rules:**
   - Media3 buffer tuning: `DefaultLoadControl.Builder().setBufferDurationsMs(15000, 30000, 1000, 2000)`.
   - Call `window.setFlags(FLAG_SECURE, ...)` **before** creating `SurfaceView`.
6. **Results & Channels:**
   - Fullscreen returns sealed `PlaybackResult` (`PlaybackCompleted`, `PlaybackCancelled`, `PlaybackFailed`).
   - Platform view ID: `plugins.video/video_player_view`. Per-view channel: `plugins.video/video_player_view_<id>`.
   - Never send embedded player commands over the main `video_player` channel.

---

## 4. Skills (Progressive Runbooks)
Detailed step-by-step procedures are offloaded to on-demand skills (located in `.claude/skills/`, available to Antigravity via `.agents/skills.json`):
- `native-feature`: Cross-layer workflow for new configs, methods, or controls.
- `darwin-typecheck`: swiftc compiler check for iOS & macOS without building.
- `android-typecheck`: Kotlin compiler check against cached jars without Gradle.
- `release-bump`: 4-file version synchronization and changelog preparation.
