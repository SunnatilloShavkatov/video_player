## [3.0.0] - TBD

### 🚨 BREAKING CHANGES

This is a major version release focused on API clarity, type safety, and developer experience improvements. No new features are added, but the public API has changed to eliminate ambiguity and prevent common misuse patterns.

#### 1. PlaybackResult replaces nullable List<int>?

**Before (v2.x):**
```
final result = await VideoPlayer.instance.playVideo(playerConfig: config);
if (result != null) {
  final position = result[0];  // What unit? Seconds? Milliseconds?
  final duration = result[1];
  // Is null = cancelled or error? Who knows!
}
```

**After (v3.0):**
```
final result = await VideoPlayer.instance.playVideo(playerConfig: config);

switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    // Clear semantics: position and duration in seconds
    print('Watched ${lastPositionSeconds}s of ${durationSeconds}s');
    await saveProgress(videoId, lastPositionSeconds);

  case PlaybackCancelled():
    // User cancelled - not an error
    print('User cancelled playback');

  case PlaybackFailed(:final error, :final stackTrace):
    // Actual error with debuggable info
    print('Error: $error');
    logError(error, stackTrace);
}
```

**Migration:**
- Replace `result != null` checks with pattern matching on `PlaybackResult`
- Time units remain in seconds (no conversion needed)
- Handle all three cases: `PlaybackCompleted`, `PlaybackCancelled`, `PlaybackFailed`

#### 2. PlayerConfiguration factory constructors

**Before (v2.x):**
```
final config = PlayerConfiguration(
  videoUrl: 'https://example.com/video.m3u8',
  title: 'My Video',
  qualityText: 'Quality',  // Boilerplate
  speedText: 'Speed',      // Boilerplate
  autoText: 'Auto',        // Boilerplate
  lastPosition: 0,         // Seconds? Milliseconds? Unclear.
  playVideoFromAsset: false,
  assetPath: '',           // Always empty for remote videos
  movieShareLink: '',
);
```

**After (v3.0):**
```
// Recommended: Use factory constructor
final config = PlayerConfiguration.remote(
  videoUrl: 'https://example.com/video.m3u8',
  title: 'My Video',
  startPositionSeconds: 120,  // Clear: 2 minutes in seconds
);

// For assets (if needed)
final assetConfig = PlayerConfiguration.asset(
  assetPath: 'videos/intro.mp4',
  title: 'Introduction',
);
```

**Migration:**
- Use `PlayerConfiguration.remote()` for HTTPS videos (recommended)
- Use `PlayerConfiguration.asset()` for asset videos
- Rename `lastPosition` to `startPositionSeconds` for clarity (value stays in seconds)
- Old constructor still works but is marked as advanced-use-only

#### 3. Stable enum serialization

**Before (v2.x):**
```
enum ResizeMode { fit, fill, zoom }
// Used enum.name for platform communication
// Renaming enum would break native code
```

**After (v3.0):**
```
enum ResizeMode {
  fit('fit'),
  fill('fill'),
  zoom('zoom');

  const ResizeMode(this.value);
  final String value;  // Stable platform contract
}
```

**Migration:**
- No code changes required
- Enums now use explicit `value` field for platform communication
- Safe to refactor enum names without breaking platforms

#### 4. Error handling normalization

**Before (v2.x):**
- Some errors threw exceptions
- Some errors returned null
- Some errors were swallowed silently

**After (v3.0):**
- **Validation errors** (invalid URL, bad config): Throw `ArgumentError` or `StateError`
- **Runtime/platform errors**: Return `PlaybackFailed` with error details
- **No silent failures**: All errors are either thrown or returned as `PlaybackFailed`

**Migration:**
```
// Before
try {
  final result = await VideoPlayer.instance.playVideo(playerConfig: config);
  if (result == null) {
    // Was this an error or cancellation? Unknown.
  }
} catch (e) {
  // Some validation error
}

// After
try {
  final result = await VideoPlayer.instance.playVideo(playerConfig: config);
  if (result is PlaybackFailed) {
    // Clear error case
    handleError(result.error);
  }
} on ArgumentError catch (e) {
  // Invalid configuration - fix before deploying
  print('Configuration error: $e');
}
```

#### 5. Hardened lifecycle guards

**Before (v2.x):**
```
controller.dispose();
controller.play(); // May cause undefined behavior
```

**After (v3.0):**
```
controller.dispose();
controller.play(); // Throws StateError with clear message
// StateError: VideoPlayerViewController is disposed and cannot be used
```

**Migration:**
- Ensure you don't call methods after `dispose()`
- If you hit `StateError`, fix your lifecycle management

### Changed

- **API**: `playVideo()` now returns `Future<PlaybackResult>` instead of `Future<List<int>?>`
- **API**: Added `PlayerConfiguration.remote()` and `PlayerConfiguration.asset()` factory constructors
- **API**: Renamed `lastPosition` to `startPositionSeconds` for clarity (unit remains seconds)
- **API**: All time values remain in seconds (int) for consistency with native platforms
- **Error Handling**: Invalid URLs now throw `ArgumentError` instead of `Exception`
- **Error Handling**: All runtime errors return `PlaybackFailed` instead of throwing or returning null
- **Enums**: `ResizeMode` and `PlayerStatus` now use explicit `value` field for serialization
- **Lifecycle**: All controller methods throw `StateError` after `dispose()`
- **Type Safety**: Eliminated nullable return types from playback methods

### Added

- **Type**: `PlaybackResult` sealed class with `PlaybackCompleted`, `PlaybackCancelled`, `PlaybackFailed` variants
- **Factory**: `PlayerConfiguration.remote()` for creating remote video configs with sensible defaults
- **Factory**: `PlayerConfiguration.asset()` for creating asset video configs
- **Method**: `ResizeMode.fromValue(String)` for stable deserialization
- **Method**: `PlayerStatus.fromValue(String)` for stable deserialization
- **Documentation**: Comprehensive API documentation for all breaking changes
- **Documentation**: Migration guide in CHANGELOG and README

### Removed

- **Type**: No longer return `List<int>?` from `playVideo()` (use `PlaybackResult` instead)

### Migration Time Estimate

- **Small apps** (1-5 call sites): ~15 minutes
- **Medium apps** (5-20 call sites): ~30-45 minutes
- **Large apps** (20+ call sites): ~1 hour

### Migration Checklist

- [ ] Replace `List<int>?` result handling with `PlaybackResult` pattern matching
- [ ] Update `PlayerConfiguration` to use `.remote()` or `.asset()` factories
- [ ] Rename `lastPosition` to `startPositionSeconds` for clarity (no value conversion needed)
- [ ] Update error handling to catch `ArgumentError` for validation errors
- [ ] Test all video playback flows
- [ ] Verify position tracking and resume functionality

## [2.1.0] - 2026-01-24

### Fixed
- **iOS**: Fixed critical memory leaks in AVPlayer observer lifecycle management
- **iOS**: Resolved KVO crashes when removing observers during deallocation
- **iOS**: Eliminated deadlock risk in observer cleanup on main thread
- **Android**: Fixed lifecycle crashes caused by Handler callbacks after disposal
- **Android**: Resolved null pointer exceptions through proper null handling
- **Android**: Fixed EGLSurfaceTexture cleanup sequence
- **Flutter**: Corrected method channel result handling (replaced undocumented fallback with proper error handling)
- **Flutter**: Fixed silent failures - all errors now propagate with logging

### Changed
- **Error Handling**: Standardized error propagation across all platforms with debug-mode logging
- **iOS**: Centralized observer lifecycle management with atomic disposal guards
- **Android**: Improved activity attachment safety and resource cleanup ordering
- **Android**: Enhanced Handler and Runnable cleanup to prevent memory leaks
- **Security**: Enforced HTTPS-only URL validation at API boundary
- **API**: Clarified return value contracts and error behavior in documentation
- **Documentation**: Updated platform-specific behavior notes for production use

### Removed
- **Download functionality**: Completely removed offline playback and download features
- **Unsafe code patterns**: Eliminated force unwraps and unchecked null assertions
- **Deprecated APIs**: Removed unused download-related interfaces and models

### Added
- **Testing**: Regression test suite covering URL validation, method channel contracts, and error propagation
- **Documentation**: Added comprehensive deployment and monitoring guidelines
- **Security**: Added test coverage for HTTPS enforcement and URL injection prevention

## 2.0.0

* Comprehensive dartdoc documentation added for all public APIs
* README updated with accurate usage examples and platform requirements
* Removed references to discontinued download features
* Added clear error documentation and platform-specific behavior notes
* Improved developer experience with detailed API documentation

## 1.0.4

* TODO: Describe initial release.

## 1.0.3

* TODO: Describe initial release.

## 1.0.2

* TODO: Describe initial release.

## 0.0.1

* TODO: Describe initial release.
