# Video Player Plugin - Public API Clarification & Hardening

## Executive Summary

This document identifies critical API contract issues in the Flutter video_player plugin and provides concrete fixes to clarify semantics, improve type safety, and prevent misuse.

**Scope**: Dart public API only (no native code changes)

---

## Critical Issues Identified

### 1. **Unclear Return Type: `Future<List<int>?>`**

**Location**: `VideoPlayer.playVideo()` and `VideoPlayerPlatform.playVideo()`

**Current Signature**:
```
Future<List<int>?> playVideo({required PlayerConfiguration playerConfig})
```

**Problems**:
- What does `List<int>` represent? Position? Duration? Both?
- What does `null` mean? Cancellation? Error? User dismissed player?
- Why is it a list? How many elements? What order?
- No documentation on the contract

**From Native Code Analysis** (VideoPlayerPlugin.kt:114):
```
resultMethod?.success(listOf(position.toInt(), duration.toInt()))
```

**Contract Discovery**:
- Index 0: Last playback position in **milliseconds**
- Index 1: Total video duration in **milliseconds**
- Returns `null` if user closes player without completion or on error

---

### 2. **Exception vs Error Code Inconsistency**

**Current Behavior**:
```
Future<List<int>?> playVideo({required PlayerConfiguration playerConfig}) {
  if (UrlValidator.instance.isNotValidHttpsUrl(playerConfig.videoUrl)) {
    throw Exception('Invalid URL format. Must be HTTPS URL');  // ❌ Throws
  } else {
    final String jsonStringConfig = _encodeConfig(playerConfig.toMap());
    return VideoPlayerPlatform.instance.playVideo(...);  // ❌ Returns null on error
  }
}
```

**Problems**:
- Validation errors **throw exceptions**
- Platform errors **return null**
- Inconsistent error handling forces try-catch AND null checks
- Caller cannot distinguish between cancellation and error

---

### 3. **Missing Documentation on PlayerConfiguration Requirements**

**Current**:
```
class PlayerConfiguration {
  const PlayerConfiguration({
    required this.videoUrl,
    required this.title,
    required this.autoText,
    required this.assetPath,
    required this.speedText,
    required this.qualityText,
    required this.lastPosition,
    required this.movieShareLink,
    required this.playVideoFromAsset,
  });
```

**Problems**:
- All fields are `required`, but some are mutually exclusive
- `videoUrl` vs `assetPath` + `playVideoFromAsset` flag - which takes precedence?
- `lastPosition` in what unit? Seconds? Milliseconds?
- `autoText`, `speedText`, `qualityText` - what format? Localized strings?
- No validation on construction

---

### 4. **VideoPlayerViewController Lifecycle Unclear**

**Current**:
```dart
final class VideoPlayerViewController {
  VideoPlayerViewController._(int id) : _channel = MethodChannel('...');

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _positionController?.close();
    // ...
  }
}
```

**Problems**:
- When should `dispose()` be called?
- What happens if methods are called after `dispose()`?
- No `@mustCallSuper` or disposal guard
- Multiple calls to `positionStream` or `statusStream` create multiple controllers

---

### 5. **Enum Serialization Fragility**

**Current**:
```
enum ResizeMode { fit, fill, zoom }

// Usage:
'resizeMode': resizeMode.name  // ❌ Relies on enum name string
```

**Problems**:
- Breaking change if enum is renamed
- No version compatibility
- Platform side must match exact string

---

### 6. **Stream Management Memory Leaks**

**Current**:
```
Stream<double> get positionStream {
  if (_positionController != null) {
    return _positionController!.stream;
  }
  _positionController = StreamController<double>.broadcast();
  _setupMethodHandler();  // ❌ Called multiple times
  return _positionController!.stream;
}
```

**Problems**:
- Calling `positionStream` multiple times recreates controllers
- `_setupMethodHandler()` sets method handler multiple times (race condition)
- No protection against multiple subscriptions

---

## Recommended Fixes

### Fix 1: Introduce Explicit Result Type

**Create new sealed class** (lib/src/models/playback_result.dart):

```
/// Result of a video playback session.
///
/// This represents the outcome when the full-screen video player is dismissed.
sealed class PlaybackResult {
  const PlaybackResult();
}

/// Video playback completed successfully.
///
/// Contains the final playback position and total duration when the user
/// closed the player.
final class PlaybackCompleted extends PlaybackResult {
  const PlaybackCompleted({
    required this.lastPositionMillis,
    required this.durationMillis,
  });

  /// Last playback position in milliseconds when player was closed
  final int lastPositionMillis;

  /// Total video duration in milliseconds
  final int durationMillis;

  /// Last playback position in seconds (convenience getter)
  double get lastPositionSeconds => lastPositionMillis / 1000.0;

  /// Total video duration in seconds (convenience getter)
  double get durationSeconds => durationMillis / 1000.0;
}

/// Video playback was cancelled by the user.
///
/// The user dismissed the player before video completed, or pressed back button.
final class PlaybackCancelled extends PlaybackResult {
  const PlaybackCancelled();
}

/// Video playback failed due to an error.
final class PlaybackFailed extends PlaybackResult {
  const PlaybackFailed(this.error, [this.stackTrace]);

  /// The error that caused playback to fail
  final Object error;

  /// Optional stack trace for debugging
  final StackTrace? stackTrace;
}
```

**Update VideoPlayer.playVideo()**:

```
/// Plays a video in full-screen native player.
///
/// Opens a native full-screen video player with the provided [playerConfig].
///
/// Returns:
/// - [PlaybackCompleted] with position/duration if user closes player normally
/// - [PlaybackCancelled] if user dismisses player (back button, swipe down)
/// - [PlaybackFailed] if playback encounters an error
///
/// Throws:
/// - [ArgumentError] if [playerConfig.videoUrl] is not a valid HTTPS URL
///
/// Example:
/// ```dart
/// final result = await VideoPlayer.instance.playVideo(
///   playerConfig: PlayerConfiguration(
///     videoUrl: 'https://example.com/video.mp4',
///     title: 'My Video',
///     // ... other config
///   ),
/// );
///
/// switch (result) {
///   case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
///     print('Watched $lastPositionSeconds of $durationSeconds seconds');
///   case PlaybackCancelled():
///     print('User cancelled playback');
///   case PlaybackFailed(:final error):
///     print('Playback failed: $error');
/// }
/// ```
Future<PlaybackResult> playVideo({
  required PlayerConfiguration playerConfig,
}) async {
  // Validate early with clear exception
  if (UrlValidator.instance.isNotValidHttpsUrl(playerConfig.videoUrl)) {
    throw ArgumentError.value(
      playerConfig.videoUrl,
      'playerConfig.videoUrl',
      'Must be a valid HTTPS URL',
    );
  }

  final String jsonStringConfig = _encodeConfig(playerConfig.toMap());

  try {
    final List<int>? result = await VideoPlayerPlatform.instance.playVideo(
      playerConfigJsonString: jsonStringConfig,
    );

    if (result == null) {
      return const PlaybackCancelled();
    }

    if (result.length != 2) {
      return PlaybackFailed(
        StateError('Invalid platform response: expected 2 elements, got ${result.length}'),
      );
    }

    return PlaybackCompleted(
      lastPositionMillis: result[0],
      durationMillis: result[1],
    );
  } catch (error, stackTrace) {
    return PlaybackFailed(error, stackTrace);
  }
}
```

---

### Fix 2: Document PlayerConfiguration Contract

**Update PlayerConfiguration with comprehensive docs**:

```
/// Configuration for full-screen native video player.
///
/// This class configures the appearance and behavior of the native video player.
///
/// ## Video Source
///
/// Exactly ONE of the following must be provided:
/// - Remote video: Set [videoUrl] (HTTPS URL) and [playVideoFromAsset] = false
/// - Local asset: Set [assetPath] (Flutter asset path) and [playVideoFromAsset] = true
///
/// ## Required UI Strings
///
/// The following fields provide localized text for UI controls:
/// - [title]: Video title shown in player header
/// - [speedText]: Label for speed control (e.g., "Speed", "Velocidad")
/// - [qualityText]: Label for quality selection (e.g., "Quality", "Qualidade")
/// - [autoText]: Label for auto quality (e.g., "Auto", "Automático")
///
/// ## Optional Features
///
/// - [lastPosition]: Resume playback from this position in **milliseconds** (default: 0)
/// - [movieShareLink]: URL to share via native share sheet (empty string = no share button)
///
/// Example:
/// ```dart
/// // Remote video
/// final config = PlayerConfiguration(
///   videoUrl: 'https://example.com/video.m3u8',
///   title: 'Episode 1',
///   speedText: 'Speed',
///   qualityText: 'Quality',
///   autoText: 'Auto',
///   lastPosition: 45000,  // Resume at 45 seconds
///   movieShareLink: 'https://example.com/share/episode1',
///   playVideoFromAsset: false,
///   assetPath: '',  // Ignored when playVideoFromAsset is false
/// );
///
/// // Local asset
/// final config = PlayerConfiguration(
///   videoUrl: '',  // Ignored when playVideoFromAsset is true
///   title: 'Tutorial',
///   speedText: 'Speed',
///   qualityText: 'Quality',
///   autoText: 'Auto',
///   lastPosition: 0,
///   movieShareLink: '',
///   playVideoFromAsset: true,
///   assetPath: 'assets/videos/tutorial.mp4',
/// );
/// ```
class PlayerConfiguration {
  const PlayerConfiguration({
    required this.videoUrl,
    required this.title,
    required this.autoText,
    required this.assetPath,
    required this.speedText,
    required this.qualityText,
    required this.lastPosition,
    required this.movieShareLink,
    required this.playVideoFromAsset,
  }) : assert(
         playVideoFromAsset && assetPath.isNotEmpty ||
         !playVideoFromAsset && videoUrl.isNotEmpty,
         'Either assetPath (if playVideoFromAsset=true) or videoUrl (if playVideoFromAsset=false) must be non-empty',
       );

  /// Video title displayed in player UI
  final String title;

  /// HTTPS URL of remote video (HLS .m3u8 or progressive .mp4)
  ///
  /// Required if [playVideoFromAsset] is false, ignored otherwise.
  final String videoUrl;

  /// Localized label for speed control button (e.g., "Speed", "Velocidad")
  final String speedText;

  /// Resume playback from this position in milliseconds
  ///
  /// Use 0 to start from beginning. Native player will seek to this position
  /// after video loads.
  final int lastPosition;

  /// Localized label for auto quality option (e.g., "Auto", "Automático")
  final String autoText;

  /// Flutter asset path to local video file
  ///
  /// Required if [playVideoFromAsset] is true, ignored otherwise.
  /// Example: 'assets/videos/intro.mp4'
  final String assetPath;

  /// Localized label for quality selection button (e.g., "Quality", "Qualidade")
  final String qualityText;

  /// URL to share via native share sheet
  ///
  /// Empty string disables the share button.
  final String movieShareLink;

  /// Whether to play from local Flutter asset (true) or remote URL (false)
  final bool playVideoFromAsset;

  // ... rest of the class
}
```

---

### Fix 3: Harden VideoPlayerViewController Lifecycle

```dart
/// Controller for an embedded video player view.
///
/// ## Lifecycle
///
/// 1. Created via [VideoPlayerView.onVideoViewCreated] callback
/// 2. Use methods to control playback
/// 3. **Must** call [dispose] when done (typically in StatefulWidget.dispose)
///
/// ## Usage
///
/// ```dart
/// class VideoScreen extends StatefulWidget {
///   @override
///   State<VideoScreen> createState() => _VideoScreenState();
/// }
///
/// class _VideoScreenState extends State<VideoScreen> {
///   VideoPlayerViewController? _controller;
///   StreamSubscription<PlayerStatus>? _statusSub;
///
///   @override
///   Widget build(BuildContext context) {
///     return VideoPlayerView(
///       url: 'https://example.com/video.mp4',
///       onVideoViewCreated: (controller) {
///         _controller = controller;
///         _statusSub = controller.statusStream.listen((status) {
///           print('Status: $status');
///         });
///       },
///     );
///   }
///
///   @override
///   void dispose() {
///     _statusSub?.cancel();
///     _controller?.dispose();
///     super.dispose();
///   }
/// }
/// ```
final class VideoPlayerViewController {
  VideoPlayerViewController._(int id)
      : _channel = MethodChannel('$_channelPrefix$id');

  static const String _channelPrefix = 'plugins.video/video_player_view_';

  final MethodChannel _channel;
  bool _isDisposed = false;

  /// Throws [StateError] if controller is already disposed
  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError(
        'VideoPlayerViewController is already disposed. '
        'Do not use this controller after calling dispose().',
      );
    }
  }

  /// Sets the video URL and resize mode.
  ///
  /// Throws:
  /// - [StateError] if controller is disposed
  /// - [ArgumentError] if [url] is not a valid HTTPS URL
  Future<void> setUrl({
    required String url,
    ResizeMode resizeMode = ResizeMode.fit,
  }) async {
    _checkNotDisposed();

    if (UrlValidator.instance.isNotValidHttpsUrl(url)) {
      throw ArgumentError.value(url, 'url', 'Must be a valid HTTPS URL');
    }

    await _channel.invokeMethod('setUrl', {
      'url': url,
      'resizeMode': resizeMode.name,
    });
  }

  /// Pauses video playback.
  ///
  /// Throws [StateError] if controller is disposed.
  Future<void> pause() async {
    _checkNotDisposed();
    await _channel.invokeMethod('pause');
  }

  /// Starts/resumes video playback.
  ///
  /// Throws [StateError] if controller is disposed.
  Future<void> play() async {
    _checkNotDisposed();
    await _channel.invokeMethod('play');
  }

  /// Gets the total duration of the video in seconds.
  ///
  /// Returns 0.0 if duration is not yet available.
  ///
  /// Throws [StateError] if controller is disposed.
  Future<double> getDuration() async {
    _checkNotDisposed();
    final result = await _channel.invokeMethod('getDuration');
    return (result as double?) ?? 0.0;
  }

  /// Seeks to a specific position in the video.
  ///
  /// [seconds] must be non-negative.
  ///
  /// Throws:
  /// - [StateError] if controller is disposed
  /// - [ArgumentError] if [seconds] is negative
  Future<void> seekTo({required double seconds}) async {
    _checkNotDisposed();

    if (seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds', 'Must be non-negative');
    }

    await _channel.invokeMethod('seekTo', {'seconds': seconds});
  }

  StreamController<double>? _positionController;
  StreamController<PlayerStatus>? _statusController;
  bool _isMethodHandlerSetup = false;

  /// Stream of current playback position in seconds.
  ///
  /// Emits position updates approximately once per second during playback.
  ///
  /// This is a broadcast stream - multiple listeners are supported.
  ///
  /// Throws [StateError] if controller is disposed.
  Stream<double> get positionStream {
    _checkNotDisposed();

    _positionController ??= StreamController<double>.broadcast();
    _ensureMethodHandlerSetup();

    return _positionController!.stream;
  }

  /// Stream of player status changes.
  ///
  /// Emits [PlayerStatus] when playback state changes (playing, paused, buffering, etc).
  ///
  /// This is a broadcast stream - multiple listeners are supported.
  ///
  /// Throws [StateError] if controller is disposed.
  Stream<PlayerStatus> get statusStream {
    _checkNotDisposed();

    _statusController ??= StreamController<PlayerStatus>.broadcast();
    _ensureMethodHandlerSetup();

    return _statusController!.stream;
  }

  void Function(Object object)? _finishedCallback;
  void Function(double)? _durationReadyCallback;

  void _ensureMethodHandlerSetup() {
    if (_isMethodHandlerSetup) return;

    _channel.setMethodCallHandler((call) async {
      if (_isDisposed) return;  // Ignore late callbacks after disposal

      switch (call.method) {
        case 'positionUpdate':
          final position = (call.arguments as double?) ?? 0.0;
          _positionController?.add(position);

        case 'durationReady':
          final duration = (call.arguments as double?) ?? 0.0;
          if (duration > 0) {
            _durationReadyCallback?.call(duration);
          }

        case 'playerStatus':
          final statusString = call.arguments as String?;
          if (statusString != null) {
            final status = PlayerStatus.values.firstWhere(
              (e) => e.name == statusString,
              orElse: () => PlayerStatus.idle,
            );
            _statusController?.add(status);
          }

        case 'finished':
          _finishedCallback?.call(call.arguments);
      }
    });

    _isMethodHandlerSetup = true;
  }

  /// Sets callback for when duration becomes available.
  ///
  /// Called automatically when the native player detects video duration.
  /// Typically fires shortly after video starts loading.
  ///
  /// Throws [StateError] if controller is disposed.
  void onDurationReady(void Function(double duration) callback) {
    _checkNotDisposed();
    _durationReadyCallback = callback;
    _ensureMethodHandlerSetup();
  }

  /// Disposes the controller and releases all resources.
  ///
  /// After calling this method, the controller cannot be used anymore.
  /// Attempting to call any methods will throw [StateError].
  ///
  /// Safe to call multiple times (subsequent calls are no-ops).
  Future<void> dispose() async {
    if (_isDisposed) return;  // Idempotent

    _isDisposed = true;
    _channel.setMethodCallHandler(null);

    await _positionController?.close();
    _positionController = null;

    await _statusController?.close();
    _statusController = null;

    _finishedCallback = null;
    _durationReadyCallback = null;
  }
}
```

---

### Fix 4: Make Enum Serialization Explicit

```
/// Video resize modes for embedded player.
///
/// Controls how video content is scaled within the player view.
enum ResizeMode {
  /// Scale to fit within view while maintaining aspect ratio (letterbox/pillarbox)
  fit('fit'),

  /// Scale to fill entire view, cropping if necessary to maintain aspect ratio
  fill('fill'),

  /// Scale to fill and center, may crop edges
  zoom('zoom');

  const ResizeMode(this.value);

  /// Platform channel value for this resize mode
  final String value;

  /// Parse from platform channel string
  static ResizeMode fromValue(String value) {
    return values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ResizeMode.fit,
    );
  }
}

// Usage in VideoPlayerView:
creationParams: <String, dynamic>{
  'url': url,
  'resizeMode': resizeMode.value,  // ✅ Explicit value
},

// Usage in VideoPlayerViewController:
await _channel.invokeMethod('setUrl', {
  'url': url,
  'resizeMode': resizeMode.value,  // ✅ Explicit value
});
```

Same pattern for PlayerStatus:

```
/// Player state values.
enum PlayerStatus {
  idle('idle'),
  buffering('buffering'),
  ready('ready'),
  playing('playing'),
  paused('paused'),
  ended('ended'),
  error('error');

  const PlayerStatus(this.value);

  final String value;

  static PlayerStatus fromValue(String value) {
    return values.firstWhere(
      (status) => status.value == value,
      orElse: () => PlayerStatus.idle,
    );
  }
}

// Update in _ensureMethodHandlerSetup:
case 'playerStatus':
  final statusString = call.arguments as String?;
  if (statusString != null) {
    final status = PlayerStatus.fromValue(statusString);  // ✅ Explicit parsing
    _statusController?.add(status);
  }
```

---

### Fix 5: Add Factory Constructors for Common Configurations

```dart
/// Additional factory constructors for PlayerConfiguration
extension PlayerConfigurationFactories on PlayerConfiguration {
  /// Creates configuration for remote video playback.
  ///
  /// Simplified constructor for common remote video use case.
  ///
  /// Example:
  /// ```dart
  /// final config = PlayerConfiguration.remote(
  ///   url: 'https://example.com/video.m3u8',
  ///   title: 'My Video',
  ///   startPosition: Duration(seconds: 30),
  /// );
  /// ```
  static PlayerConfiguration remote({
    required String url,
    required String title,
    String speedText = 'Speed',
    String qualityText = 'Quality',
    String autoText = 'Auto',
    Duration startPosition = Duration.zero,
    String? shareUrl,
  }) {
    return PlayerConfiguration(
      videoUrl: url,
      title: title,
      speedText: speedText,
      qualityText: qualityText,
      autoText: autoText,
      lastPosition: startPosition.inMilliseconds,
      movieShareLink: shareUrl ?? '',
      playVideoFromAsset: false,
      assetPath: '',
    );
  }

  /// Creates configuration for local asset playback.
  ///
  /// Simplified constructor for local asset video.
  ///
  /// Example:
  /// ```dart
  /// final config = PlayerConfiguration.asset(
  ///   path: 'assets/videos/intro.mp4',
  ///   title: 'Introduction',
  /// );
  /// ```
  static PlayerConfiguration asset({
    required String path,
    required String title,
    String speedText = 'Speed',
    String qualityText = 'Quality',
    String autoText = 'Auto',
  }) {
    return PlayerConfiguration(
      videoUrl: '',
      title: title,
      speedText: speedText,
      qualityText: qualityText,
      autoText: autoText,
      lastPosition: 0,
      movieShareLink: '',
      playVideoFromAsset: true,
      assetPath: path,
    );
  }
}
```

---

## Migration Guide

### For Library Users

**Before**:
```
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration(
    videoUrl: 'https://example.com/video.mp4',
    title: 'Video',
    autoText: 'Auto',
    assetPath: '',
    speedText: 'Speed',
    qualityText: 'Quality',
    lastPosition: 0,
    movieShareLink: '',
    playVideoFromAsset: false,
  ),
);

if (result != null) {
  final position = result[0];  // What is this?
  final duration = result[1];  // What is this?
  print('Position: $position, Duration: $duration');
} else {
  print('Failed or cancelled?');  // Can't tell which
}
```

**After**:
```
final result = await VideoPlayer.instance.playVideo(
  playerConfig: PlayerConfiguration.remote(
    url: 'https://example.com/video.mp4',
    title: 'Video',
  ),
);

switch (result) {
  case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
    print('Watched $lastPositionSeconds of $durationSeconds seconds');

  case PlaybackCancelled():
    print('User cancelled playback');

  case PlaybackFailed(:final error):
    print('Error: $error');
}
```

---

## Implementation Checklist

- [ ] Create `PlaybackResult` sealed class hierarchy
- [ ] Update `VideoPlayer.playVideo()` return type and documentation
- [ ] Update `VideoPlayerPlatform.playVideo()` signature
- [ ] Update `MethodChannelVideoPlayer.playVideo()` to handle error cases
- [ ] Add comprehensive dartdoc to `PlayerConfiguration`
- [ ] Add `assert` to `PlayerConfiguration` constructor
- [ ] Add factory constructors `PlayerConfiguration.remote()` and `.asset()`
- [ ] Add explicit `value` field to `ResizeMode` enum
- [ ] Add explicit `value` field to `PlayerStatus` enum
- [ ] Add `fromValue()` static methods to enums
- [ ] Add `_isDisposed` flag to `VideoPlayerViewController`
- [ ] Add `_checkNotDisposed()` guard method
- [ ] Add disposal guards to all `VideoPlayerViewController` methods
- [ ] Fix `_ensureMethodHandlerSetup()` to be idempotent
- [ ] Add argument validation (negative seconds, empty URLs)
- [ ] Write API usage examples in README
- [ ] Update CHANGELOG with breaking changes note

---

## Benefits

1. **Type Safety**: Sealed class pattern forces exhaustive handling
2. **Self-Documenting**: Clear names (`PlaybackCompleted` vs `List<int>?`)
3. **Error Handling**: Distinguish cancellation from errors
4. **Units Clarity**: Explicit milliseconds vs seconds accessors
5. **Lifecycle Safety**: Disposal guards prevent use-after-free
6. **Enum Stability**: Explicit values prevent breaking changes
7. **Reduced Misuse**: Factory constructors guide correct usage
8. **Better Tooling**: IDEs can provide better autocomplete and hints

---

## Backward Compatibility Notes

**Breaking Changes**:
- `playVideo()` return type changes from `Future<List<int>?>` to `Future<PlaybackResult>`
- `ResizeMode.name` replaced with `ResizeMode.value`
- `PlayerStatus.name` replaced with `PlayerStatus.value`

**Migration Effort**: Low (1-2 hours for typical app)

**Recommendation**: Introduce in next major version (3.0.0)
