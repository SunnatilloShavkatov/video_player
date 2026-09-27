---
name: android-typecheck
description: Typecheck the plugin's Kotlin sources (android/src/main/kotlin) with the Kotlin compiler from the Gradle cache, without running Gradle or building the example app. Use after any Android change — new or moved files, package renames, refactors, signature changes — before handing the diff to the user.
---

# Android typecheck

This project's rule is **not** to run Gradle or `flutter build apk` without asking. This skill
gives a compile signal from jars already in `~/.gradle/caches`.

## Run

```bash
.claude/skills/android-typecheck/scripts/typecheck.sh
```

What it does:
1. Extracts `classes.jar` from the cached AARs (androidx, Material, Gson; Media3 pinned to the
   version in `android/build.gradle.kts`). It caches them in `$TMPDIR/video_player_android_typecheck`.
2. Generates stub `R` and ViewBinding classes from `android/src/main/res` (normally made by AGP).
3. Compiles every `.kt` file with `K2JVMCompiler` against `android.jar` + Flutter embedding.

Success prints `Android: OK`.

## Reading the result

- Any `error:` in a file you touched is real. Fix it.
- Compare against HEAD before blaming your change. Extract HEAD with
  `git archive HEAD android/src/main/kotlin | tar -x -C <dir>`, then run
  `typecheck.sh <dir>/android/src/main/kotlin` on it.
- The stubs don't check resource *existence* beyond what's in `res/`, or layout-to-type accuracy
  for `<include>`/`<merge>`. Lint, manifest merging and R8 are not covered at all.

## If it can't find the compiler or SDK

The Gradle cache or Android SDK is missing, so the project was never built on this machine.
Ask the user before running any Gradle task.
