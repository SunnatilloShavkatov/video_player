import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:video_player/src/utils/log_message.dart';
import 'package:video_player/src/utils/url_validator.dart';

/// Video resize mode for embedded player view.
///
/// Determines how video content fits within the player view bounds.
enum ResizeMode {
  /// Fit video within view bounds while maintaining aspect ratio.
  ///
  /// Video is scaled to fit entirely within the view. Black bars may appear
  /// if aspect ratios don't match.
  fit('fit'),

  /// Fill the entire view, cropping video if necessary.
  ///
  /// Video is scaled to fill the view completely. Parts of the video may be
  /// cropped if aspect ratios don't match.
  fill('fill'),

  /// Zoom video to fill view while maintaining aspect ratio.
  ///
  /// Similar to fill, but ensures the entire video area is visible.
  zoom('zoom');

  const ResizeMode(this.value);

  /// Platform-stable serialization value.
  ///
  /// This value is used for method channel communication with native platforms.
  /// Changing this value would break platform compatibility.
  final String value;

  /// Creates a [ResizeMode] from its platform value.
  ///
  /// Throws [ArgumentError] if the value is not recognized.
  static ResizeMode fromValue(String value) => ResizeMode.values.firstWhere(
    (mode) => mode.value == value,
    orElse: () => throw ArgumentError('Invalid ResizeMode value: $value'),
  );
}

/// Player status for embedded player view.
///
/// Represents the current state of the video player.
enum PlayerStatus {
  /// Player is idle and no video is loaded.
  idle('idle'),

  /// Player is buffering video data.
  ///
  /// This state occurs when the player is loading video data from the network
  /// or waiting for buffered data to catch up during playback.
  buffering('buffering'),

  /// Player is ready to play.
  ///
  /// Video has loaded successfully and is ready for playback.
  ready('ready'),

  /// Video playback has ended.
  ///
  /// The player has reached the end of the video content.
  ended('ended'),

  /// Video is currently playing.
  playing('playing'),

  /// Video is paused.
  paused('paused'),

  /// Player encountered an error.
  ///
  /// Playback cannot continue due to an error condition.
  error('error');

  const PlayerStatus(this.value);

  /// Platform-stable serialization value.
  ///
  /// This value is used for method channel communication with native platforms.
  /// Changing this value would break platform compatibility.
  final String value;

  /// Creates a [PlayerStatus] from its platform value.
  ///
  /// Returns [PlayerStatus.idle] if the value is not recognized,
  /// providing a safe fallback for unknown status values.
  static PlayerStatus fromValue(String value) =>
      PlayerStatus.values.firstWhere((status) => status.value == value, orElse: () => PlayerStatus.idle);
}

typedef FlutterVideoPlayerViewCreatedCallback = void Function(VideoPlayerViewController controller);

class VideoPlayerView extends StatelessWidget {
  const VideoPlayerView({
    super.key,
    required this.url,
    required this.onVideoViewCreated,
    this.resizeMode = ResizeMode.fit,
  });

  /// Platform view type name for video player
  static const String _viewType = 'plugins.video/video_player_view';

  final String url;
  final ResizeMode resizeMode;
  final FlutterVideoPlayerViewCreatedCallback onVideoViewCreated;

  @override
  Widget build(BuildContext context) {
    if (UrlValidator.instance.isNotValidHttpsUrl(url)) {
      return const Center(
        child: Text('Error: Invalid URL format. Must be HTTPS URL', style: TextStyle(color: Colors.white)),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: <String, dynamic>{'url': url, 'resizeMode': resizeMode.value},
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: <String, dynamic>{'url': url, 'resizeMode': resizeMode.value},
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.fuchsia:
        return Text('$defaultTargetPlatform is not yet supported by the web_view plugin');
      case TargetPlatform.windows:
        return Text('$defaultTargetPlatform is not yet supported by the web_view plugin');
      case TargetPlatform.linux:
        return Text('$defaultTargetPlatform is not yet supported by the web_view plugin');
      case TargetPlatform.macOS:
        return Text('$defaultTargetPlatform is not yet supported by the web_view plugin');
    }
  }

  // Callback method when platform view is created
  void _onPlatformViewCreated(int id) => onVideoViewCreated(VideoPlayerViewController._(id));
}

/// Controller for the embedded video player view.
///
/// This controller provides methods to control video playback, retrieve
/// playback information, and listen to player events.
///
/// **Lifecycle:**
/// 1. Controller is created when [VideoPlayerView] is initialized
/// 2. Use controller methods to control playback
/// 3. Listen to streams for position and status updates
/// 4. Call [dispose] when done to clean up resources
///
/// **Example:**
/// ```
/// late VideoPlayerViewController _controller;
///
/// VideoPlayerView(
///   url: 'https://example.com/video.m3u8',
///   onVideoViewCreated: (controller) {
///     _controller = controller;
///
///     // Start playback
///     controller.play();
///
///     // Monitor position
///     controller.positionStream.listen((seconds) {
///       print('Position: $seconds');
///     });
///   },
/// )
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
/// ```
final class VideoPlayerViewController {
  VideoPlayerViewController._(int id) : _channel = MethodChannel('$_channelPrefix$id') {
    _setupMethodHandler();
  }

  /// Method channel name prefix for video player view controllers
  static const String _channelPrefix = 'plugins.video/video_player_view_';

  final MethodChannel _channel;
  bool _isDisposed = false;

  void _checkNotDisposed() {
    if (_isDisposed) {
      throw StateError('VideoPlayerViewController is disposed and cannot be used');
    }
  }

  /// Changes the video URL and starts playing the new video.
  ///
  /// **Parameters:**
  /// - [url]: New HTTPS URL to play (required)
  /// - [resizeMode]: How the new video should fit in the view (default: [ResizeMode.fit])
  ///
  /// **Example:**
  /// ```
  /// await controller.setUrl(
  ///   url: 'https://example.com/another-video.m3u8',
  ///   resizeMode: ResizeMode.fill,
  /// );
  /// ```
  ///
  /// **Note:** This replaces the current video and resets playback position to 0.
  Future<void> setUrl({required String url, ResizeMode resizeMode = ResizeMode.fit}) async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('setUrl', {'url': url, 'resizeMode': resizeMode.value});
    } catch (e, s) {
      logMessage('setUrl failed', error: e, stackTrace: s);
    }
  }

  /// Loads and plays a video from Flutter assets.
  ///
  /// **Parameters:**
  /// - [assets]: Asset path relative to `assets/` directory (required)
  /// - [resizeMode]: How the video should fit in the view (default: [ResizeMode.fit])
  ///
  /// **Example:**
  /// ```
  /// await controller.setAssets(
  ///   assets: 'videos/intro.mp4',
  ///   resizeMode: ResizeMode.fit,
  /// );
  /// ```
  ///
  /// **Note:** Make sure the asset is declared in `pubspec.yaml`:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/videos/intro.mp4
  /// ```
  Future<void> setAssets({required String assets, ResizeMode resizeMode = ResizeMode.fit}) async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('setAssets', {'assets': assets, 'resizeMode': resizeMode.value});
    } catch (e, s) {
      logMessage('setAssets failed', error: e, stackTrace: s);
    }
  }

  /// Pauses video playback.
  ///
  /// Playback position is preserved. Use [play] to resume.
  ///
  /// **Example:**
  /// ```
  /// await controller.pause();
  /// ```
  Future<void> pause() async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('pause');
    } catch (e, s) {
      logMessage('pause failed', error: e, stackTrace: s);
    }
  }

  /// Starts or resumes video playback.
  ///
  /// If video is paused, playback resumes from current position.
  /// If video hasn't started yet, playback begins from the start.
  ///
  /// **Example:**
  /// ```
  /// await controller.play();
  /// ```
  Future<void> play() async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('play');
    } catch (e, s) {
      logMessage('play failed', error: e, stackTrace: s);
    }
  }

  /// Mutes the video audio.
  ///
  /// Video continues playing but without sound.
  /// Use [unmute] to restore audio.
  ///
  /// **Example:**
  /// ```
  /// await controller.mute();
  /// ```
  Future<void> mute() async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('mute');
    } catch (e, s) {
      logMessage('mute failed', error: e, stackTrace: s);
    }
  }

  /// Unmutes the video audio.
  ///
  /// Restores audio if previously muted with [mute].
  ///
  /// **Example:**
  /// ```
  /// await controller.unmute();
  /// ```
  Future<void> unmute() async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('unmute');
    } catch (e, s) {
      logMessage('unmute failed', error: e, stackTrace: s);
    }
  }

  /// Gets the total duration of the currently loaded video.
  ///
  /// **Returns:**
  /// - Video duration in seconds as a [double]
  /// - `0.0` if video is not yet loaded or duration is unavailable
  ///
  /// **Example:**
  /// ```
  /// final duration = await controller.getDuration();
  /// print('Video is ${duration.toInt()} seconds long');
  /// ```
  ///
  /// **Note:** Duration becomes available after the video loads,
  /// typically when player status changes to [PlayerStatus.ready].
  /// Use [onDurationReady] callback for automatic notification.
  Future<double> getDuration() async {
    try {
      _checkNotDisposed();
      final result = await _channel.invokeMethod('getDuration');
      return (result as double?) ?? 0.0;
    } catch (e, s) {
      logMessage('getDuration failed', error: e, stackTrace: s);
    }
    return 0;
  }

  /// Seeks to a specific position in the video.
  ///
  /// **Parameters:**
  /// - [seconds]: Target position in seconds (required). Must be >= 0 and <= video duration.
  ///
  /// **Example:**
  /// ```
  /// // Seek to 2 minutes 30 seconds
  /// await controller.seekTo(seconds: 150.0);
  ///
  /// // Seek to beginning
  /// await controller.seekTo(seconds: 0.0);
  ///
  /// // Seek to 75% through the video
  /// final duration = await controller.getDuration();
  /// await controller.seekTo(seconds: duration * 0.75);
  /// ```
  ///
  /// **Note:** Seeking may trigger buffering. Monitor [statusStream]
  /// for [PlayerStatus.buffering] and [PlayerStatus.ready] states.
  Future<void> seekTo({required double seconds}) async {
    try {
      _checkNotDisposed();
      await _channel.invokeMethod('seekTo', {'seconds': seconds});
    } catch (e, s) {
      logMessage('seekTo failed', error: e, stackTrace: s);
    }
  }

  StreamController<double>? _positionController;
  StreamController<PlayerStatus>? _statusController;

  /// Stream of current playback position in seconds.
  ///
  /// Emits position updates approximately every 1 second during playback.
  /// Position is reported in seconds as a [double] value.
  ///
  /// **Example:**
  /// ```
  /// controller.positionStream.listen((position) {
  ///   print('Current position: ${position.toStringAsFixed(1)}s');
  ///
  ///   // Update UI progress bar
  ///   final progress = position / totalDuration;
  ///   setState(() => _progress = progress);
  /// });
  /// ```
  ///
  /// **Note:** This stream is broadcast and can have multiple listeners.
  /// Remember to cancel subscriptions or call [dispose] to prevent memory leaks.
  Stream<double> get positionStream {
    _checkNotDisposed();
    _positionController ??= StreamController<double>.broadcast();
    return _positionController!.stream;
  }

  /// Stream of player status changes.
  ///
  /// Emits [PlayerStatus] values whenever the player state changes
  /// (e.g., from buffering to ready, ready to playing, playing to paused).
  ///
  /// **Example:**
  /// ```
  /// controller.statusStream.listen((status) {
  ///   switch (status) {
  ///     case PlayerStatus.buffering:
  ///       showLoadingIndicator();
  ///       break;
  ///     case PlayerStatus.ready:
  ///       hideLoadingIndicator();
  ///       break;
  ///     case PlayerStatus.ended:
  ///       onVideoComplete();
  ///       break;
  ///     case PlayerStatus.error:
  ///       showError('Playback failed');
  ///       break;
  ///     default:
  ///       break;
  ///   }
  /// });
  /// ```
  ///
  /// **Note:** This stream is broadcast and can have multiple listeners.
  Stream<PlayerStatus> get statusStream {
    _checkNotDisposed();
    _statusController ??= StreamController<PlayerStatus>.broadcast();
    return _statusController!.stream;
  }

  void Function(Object object)? _finishedCallback;

  /// Sets a callback to be invoked when video playback finishes.
  ///
  /// **Parameters:**
  /// - [onFinished]: Callback function receiving playback data when video ends
  ///
  /// **Throws:**
  /// - [StateError] if called after [dispose]
  ///
  /// **Example:**
  /// ```
  /// controller.setEventListener((data) {
  ///   print('Video finished with data: $data');
  /// });
  /// ```
  ///
  /// **Deprecated:** Consider using [statusStream] instead and listening
  /// for [PlayerStatus.ended] events for a more reactive approach.
  void setEventListener(void Function(Object object)? onFinished) {
    _checkNotDisposed();
    _finishedCallback = onFinished;
    _setupMethodHandler();
  }

  void Function(double)? _durationReadyCallback;

  /// Sets up the method call handler for receiving events from native platform.
  ///
  /// This handler is set only once during controller initialization and processes:
  /// - Position updates during playback
  /// - Duration ready notifications
  /// - Player status changes
  /// - Playback finished events
  ///
  /// All callbacks check disposal state before executing to prevent use-after-dispose errors.
  void _setupMethodHandler() {
    _channel.setMethodCallHandler((call) async {
      // Ignore all callbacks if disposed
      if (_isDisposed) {
        return;
      }

      switch (call.method) {
        case 'positionUpdate':
          final position = (call.arguments as double?) ?? 0.0;
          if (!_isDisposed) {
            _positionController?.add(position);
          }
        case 'durationReady':
          final duration = (call.arguments as double?) ?? 0.0;
          if (!_isDisposed && duration > 0 && _durationReadyCallback != null) {
            _durationReadyCallback!(duration);
          }
        case 'playerStatus':
          final statusString = call.arguments as String?;
          if (!_isDisposed && statusString != null) {
            final status = PlayerStatus.fromValue(statusString);
            _statusController?.add(status);
          }
        case 'finished':
          if (!_isDisposed && _finishedCallback != null) {
            _finishedCallback!(call.arguments);
          }
        default:
          break;
      }
    });
  }

  /// Sets a callback to be invoked when the video duration becomes available.
  ///
  /// The duration becomes available shortly after the video loads successfully,
  /// typically when the player transitions to [PlayerStatus.ready] state.
  ///
  /// **Parameters:**
  /// - [callback]: Function receiving duration in seconds as a [double]
  ///
  /// **Throws:**
  /// - [StateError] if called after [dispose]
  ///
  /// **Example:**
  /// ```
  /// controller.onDurationReady((duration) {
  ///   print('Video duration: ${duration.toInt()} seconds');
  ///   setState(() => _totalDuration = duration);
  /// });
  /// ```
  ///
  /// **Alternative:** You can also use [getDuration] after receiving
  /// [PlayerStatus.ready] from [statusStream].
  void onDurationReady(void Function(double duration) callback) {
    _checkNotDisposed();
    _durationReadyCallback = callback;
    _setupMethodHandler();
  }

  /// Disposes the controller and cleans up all resources.
  ///
  /// **IMPORTANT:** Always call this method when the controller is no longer needed
  /// to prevent memory leaks. Typically called in the widget's `dispose()` method.
  ///
  /// This method:
  /// - Closes all stream controllers
  /// - Removes method call handlers
  /// - Clears all callbacks
  ///
  /// **Example:**
  /// ```
  /// class MyVideoWidget extends StatefulWidget {
  ///   // ...
  /// }
  ///
  /// class _MyVideoWidgetState extends State<MyVideoWidget> {
  ///   late VideoPlayerViewController _controller;
  ///
  ///   @override
  ///   void dispose() {
  ///     _controller.dispose(); // Clean up resources
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  ///
  /// **Note:** After calling dispose, the controller should not be used anymore.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
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
