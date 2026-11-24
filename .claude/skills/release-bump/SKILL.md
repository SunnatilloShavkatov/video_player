---
name: release-bump
description: Prepare a video_player release — bump the version in all three places and turn the CHANGELOG's Unreleased section into a dated release. Use when the user asks to bump the version, cut a release, or prepare X.Y.Z. Stops before git commit/tag.
---

# Release bump

The version lives in three files and they must match (Darwin is SPM only; there is no podspec):

| File                          | Line                                                   |
|-------------------------------|--------------------------------------------------------|
| `pubspec.yaml`                | `version: X.Y.Z`                                       |
| `android/build.gradle.kts`    | `version = "X.Y.Z"`                                    |
| `CHANGELOG.md`                | `## [X.Y.Z] - YYYY-MM-DD` (replaces `## [Unreleased]`) |

Also update the "Current Version" line in `CLAUDE.md` if present.

## Steps

1. Ask for the version if the user didn't give one. Default: patch for fixes, minor for
   features; if the Unreleased section has a **Breaking** entry, ask how to version it.
2. Edit the three files. Use today's date.
3. Check they agree:
   ```bash
   grep -n "^version" pubspec.yaml android/build.gradle.kts; head -1 CHANGELOG.md
   ```
4. Run `flutter test`.
5. **Stop.** Show the diff. The user commits, tags (`vX.Y.Z`) and pushes themselves —
   never run `git commit`, `git tag`, or `git push`.

Users install from git refs, not pub.dev — never run `flutter pub publish`.
