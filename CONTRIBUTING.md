# Contributing to Video Player Plugin

Thank you for considering contributing to the video_player plugin! This document provides guidelines and requirements for contributing to ensure code quality and project maintainability.

## Code of Conduct

- Be respectful and constructive in all interactions
- Focus on what is best for the community and the project
- Show empathy towards other contributors

## Before You Start

1. **Check existing issues**: Look for existing issues or feature requests before creating new ones
2. **Discuss major changes**: For significant changes, open an issue first to discuss your approach
3. **Follow the style guide**: Ensure your code follows the established patterns

## Development Setup

### Requirements

- **Flutter SDK**: >=3.38.0
- **Dart**: >=3.10.0 <4.0.0
- **iOS**: Xcode 15+ for iOS development (macOS required)
- **Android**: Android Studio with SDK API 26+

### Getting Started

```bash
# Clone the repository
git clone https://github.com/SunnatilloShavkatov/video_player.git
cd video_player

# Get dependencies
flutter pub get

# Run example app
cd example
flutter run
```

## Code Style Guidelines

### Dart Code

- **Follow official Dart style guide**: https://dart.dev/guides/language/effective-dart/style
- **Use `analysis_lints`**: All code must pass linting with `analysis_lints: ^1.0.5`
- **Add dartdoc comments**: All public APIs must have comprehensive documentation
- **Use explicit types**: Avoid `var` for public API return types

```dart
// ✅ Good
/// Gets the video duration in seconds.
///
/// Returns 0.0 if duration is not available.
Future<double> getDuration() async { ... }

// ❌ Bad  
Future<double> getDuration() async { ... }  // Missing documentation
```

### Swift Code (iOS)

- **No force unwraps (`!`)**: Use optional binding or guard statements instead
- **Use weak self in closures**: Prevent retain cycles
- **Follow memory management best practices**: Clean up observers, timers, and subscriptions

```swift
// ✅ Good
guard let self = self else { return }
if let player = player {
    player.pause()
}

// ❌ Bad
self!.player!.pause()  // Force unwrap can crash
```

### Kotlin Code (Android)

- **Follow Kotlin coding conventions**: https://kotlinlang.org/docs/coding-conventions.html
- **Use WeakReference for callbacks**: Prevent memory leaks
- **Clean up resources**: Properly dispose of ExoPlayer, Handlers, and listeners

```kotlin
// ✅ Good
private class PositionUpdateRunnable(view: VideoPlayerView) : Runnable {
    private val viewRef = WeakReference(view)
    // ...
}

// ❌ Bad
private val updateTask = object : Runnable {
    override fun run() {
        // Direct reference can leak
    }
}
```

## Lifecycle Safety Rules

### Critical Requirements

These rules are **MANDATORY** to prevent crashes and memory leaks:

1. **Always check disposal state** before operations
2. **No operations after `dispose()`** - throw `StateError`
3. **Clean up in correct order**:
   - Stop async operations (timers, streams)
   - Remove observers and listeners
   - Clear method handlers
   - Release native resources
   - Set references to null

### iOS Lifecycle

```swift
// ✅ Correct disposal order
func dispose() {
    isDisposed = true
    player.pause()
    removeTimeObserver()
    NotificationCenter.default.removeObserver(self)
    removeAllObservers()  // KVO cleanup
    player.replaceCurrentItem(with: nil)
    playerLayer.removeFromSuperlayer()
}
```

### Android Lifecycle

```kotlin
// ✅ Correct disposal order
fun dispose() {
    if (!isDisposed.compareAndSet(false, true)) return
    stopPositionUpdates()
    handler.removeCallbacksAndMessages(null)
    player.removeListener(playerListener)
    methodChannel.setMethodCallHandler(null)
    player.stop()
    player.clearVideoSurface()  // Critical: before release()
    playerView.player = null
    player.release()
}
```

### Dart Lifecycle

```dart
// ✅ Add disposal guard
void _checkNotDisposed() {
  if (_isDisposed) {
    throw StateError('Controller is disposed and cannot be used');
  }
}

Future<void> play() async {
  _checkNotDisposed();
  await _channel.invokeMethod('play');
}
```

## Testing Requirements

### Before Submitting

1. **Test on physical devices**: Simulators/emulators don't catch all issues
2. **Test lifecycle**: Open/close video player 50+ times rapidly
3. **Test memory**: Use profiling tools to check for leaks
4. **Test error cases**: Invalid URLs, network failures, rapid operations

### Required Testing

- [ ] Video playback from HTTPS URL works
- [ ] Video playback resumes at correct position
- [ ] Quality and speed selection work
- [ ] Player disposes cleanly without crashes
- [ ] No memory leaks after multiple open/close cycles
- [ ] Error handling works correctly

### Memory Leak Testing

**iOS**: Use Xcode Instruments → Leaks
```bash
# Check for retained AVPlayer objects
# Check for KVO observer leaks
```

**Android**: Use Android Studio Profiler → Memory
```bash
# Check for ExoPlayer instances
# Check for Handler/Runnable leaks
```

## Pull Request Process

### Before Opening a PR

1. **Run linters**: `flutter analyze` must pass with no errors
2. **Update documentation**: If you changed APIs, update README and dartdocs
3. **Test thoroughly**: On both iOS and Android
4. **Keep changes minimal**: Focus on one issue per PR

### PR Checklist

When opening a pull request, ensure:

- [ ] Code follows style guidelines (Dart, Swift, Kotlin)
- [ ] No force unwraps in Swift code
- [ ] Lifecycle safety rules followed (disposal guards, cleanup order)
- [ ] Memory cleanup implemented correctly
- [ ] All public APIs have dartdoc comments
- [ ] Tests pass on iOS and Android
- [ ] No new memory leaks introduced
- [ ] Platform symmetry maintained (iOS/Android behavior consistent)
- [ ] CHANGELOG.md updated if needed
- [ ] README.md updated if APIs changed

### PR Title Format

```
type: brief description

Examples:
fix: Correct memory leak in VideoPlayerViewController
feat: Add Picture-in-Picture support for Android
docs: Update migration guide for v3.0.0
refactor: Improve error handling in playback
```

## Platform Symmetry

Maintain consistent behavior across platforms unless platform limitations require differences:

- **Return types**: Same types and units (seconds for time)
- **Error messages**: Consistent error descriptions
- **Lifecycle**: Similar initialization and disposal patterns
- **API surface**: Same methods available (where possible)

## Deprecation Policy

When deprecating APIs:

1. Mark with `@Deprecated` annotation
2. Provide migration path in dartdoc
3. Keep deprecated API for at least one major version
4. Document in CHANGELOG under "Deprecated" section

```dart
@Deprecated('Use PlayerConfiguration.remote() instead. Will be removed in v4.0.0')
PlayerConfiguration(...);
```

## Security Guidelines

- **HTTPS only**: Always enforce HTTPS for remote videos
- **Validate inputs**: Check URLs, time values, parameters
- **No secrets in code**: Use environment variables or secure storage
- **Handle errors gracefully**: Don't expose internal details to users

## Questions or Problems?

- **Open an issue**: For bugs or feature requests
- **Check documentation**: README.md, API docs, and code comments
- **Review existing PRs**: See how others have solved similar problems

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to video_player!** 🎉
