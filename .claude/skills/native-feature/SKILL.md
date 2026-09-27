---
name: native-feature
description: Add or change a player feature end-to-end across Dart, the method channel, Darwin (iOS + macOS) and Android, putting each piece of logic in the right component file. Use for any new PlayerConfiguration field, channel method, embedded-controller API, or full-screen player behavior (controls, subtitles, recovery, gestures).
---

# Native feature workflow

Read `AGENTS.md` first — it holds the contracts (seconds-not-milliseconds, enum stability,
HTTPS-only, channel names). This skill is the step order and the "where does it go" map.

## 1. Dart contract

| Change             | Files                                                                                                                     |
|--------------------|---------------------------------------------------------------------------------------------------------------------------|
| Full-screen option | `lib/src/models/player_configuration.dart` (field, `toMap`, `toString`, `remote`)                                         |
| Full-screen method | `lib/src/video_player_platform_interface.dart` → `lib/src/video_player_method_channel.dart` → `lib/src/video_player.dart` |
| Embedded API       | `lib/src/video_player_view.dart` (per-view channel `plugins.video/video_player_view_<id>`)                                |

Add or extend a test in `test/` for every serialized key or channel method.

## 2. Native — put logic in the component that owns it

**iOS full-screen** (`darwin/.../iOS/`) — `Player/PlayerView.swift` is an orchestrator only:

| Logic | File |
|---|---|
| Buttons, labels, slider, SnapKit layout | `Player/PlayerOverlayView.swift` |
| play / pause / seek / rate | `Player/PlayerController.swift` |
| KVO, notifications, periodic time | `Player/PlayerObserverManager.swift` |
| tap / pan / pinch | `Player/PlayerGestureHandler.swift` |
| controls visibility, time labels, spinner | `Player/PlayerControlsCoordinator.swift` |
| stall / network / foreground recovery | `Player/PlaybackRecoveryManager.swift` |
| WebVTT subtitles | `Subtitles/SubtitleController.swift` |
| settings sheets, PiP, screen protection, result reporting | `FullScreen/VideoPlayerViewController.swift` |

**iOS embedded**: `Embedded/VideoViewController.swift` (+ `VideoPlayerView.swift` for the channel).
**macOS**: `macOS/VideoPlayerOverlayView.swift` (full-screen), `macOS/VideoPlayerPlatformView.swift` (embedded).
**Shared Darwin** models/loaders: `Common/` (compiled for both platforms — no UIKit/AppKit imports).
**Android**: `VideoPlayerPlugin.kt`, `fullscreen/VideoPlayerActivity.kt`, `player/PlayerController.kt`,
`embedded/VideoPlayerView.kt` (embedded), config parsing in `models/PlayerConfiguration.kt`.

Rules:
- If a change would push `PlayerView.swift` past ~450 lines or mix a second concern into it,
  add or extend a component instead.
- A new Darwin file goes in the folder for its role; the podspec globs `iOS/**`, `macOS/**`,
  `Common/**`, so no build-file edit is needed. Never put iOS-only code in `Common/`.
- Every iOS/macOS file is wrapped in `#if os(iOS)` / `#if os(macOS)` like its neighbors.

## 3. Verify

```bash
flutter test -r failures-only
.claude/skills/darwin-typecheck/scripts/typecheck.sh
.claude/skills/android-typecheck/scripts/typecheck.sh
```

Fast compile checks exist for both Darwin and Android; don't run Gradle/`flutter build` without asking.
List the device checks the user should do (open/close the player many times for lifecycle
changes; physical iOS device for screen protection).

## 4. Document

- `CHANGELOG.md`: entry under `## [Unreleased]`, prefixed with the platform(s) in bold.
- `README.md` if the public API changed.
- `AGENTS.md` if you added a component, folder, or contract.
