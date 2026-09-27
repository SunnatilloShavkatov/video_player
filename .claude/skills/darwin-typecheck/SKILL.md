---
name: darwin-typecheck
description: Typecheck the plugin's Swift sources (iOS and macOS) with swiftc, without running `flutter build` or the example app. Use after any change under darwin/ — new files, moved files, refactors, signature changes — to confirm the code compiles before handing the diff to the user.
---

# Darwin typecheck

Native Swift changes can't be hot-reloaded, and this project's rule is **not** to run
`flutter build ios/macos` without asking. This skill gives a fast compile signal instead.

## Run

```bash
.claude/skills/darwin-typecheck/scripts/typecheck.sh        # iOS + macOS
.claude/skills/darwin-typecheck/scripts/typecheck.sh ios
.claude/skills/darwin-typecheck/scripts/typecheck.sh macos
```

The script typechecks exactly what the podspec compiles per platform:
- iOS: `Common/**` + `iOS/**` + `VideoPlayerPlugin.swift`, against Flutter.framework and SnapKit
- macOS: `Common/**` + `macOS/**` + `VideoPlayerPlugin.swift`, against FlutterMacOS.framework

## Reading the result

- Success prints `iOS: OK` / `macOS: OK`. Any `error:` line is a real failure — fix it.
- Warnings are printed too. Pre-existing ones (deprecated `imageEdgeInsets`, unreachable
  `catch` in `VideoViewController`) are known; don't introduce new ones in files you touch.
- A warning like *"nearly matches optional requirement"* means an Objective-C protocol
  method has the wrong signature and **will never be called** — treat it as an error.

## If SnapKit isn't found

The script looks for SnapKit sources in `example/build/ios/SourcePackages`, `example/ios/Pods`,
and Xcode DerivedData. If none exist, the example has never been resolved on this machine.
Ask the user before running `pod install` or any build; the macOS check still works.

## Limits

This is a compile check, not a runtime check. Behavior changes (playback, gestures, PiP,
screen protection) still need the example app on a device — tell the user what to test.
