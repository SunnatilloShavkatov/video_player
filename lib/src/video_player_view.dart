import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef FlutterVideoPlayerViewCreatedCallback = void Function(VideoPlayerViewController controller);

class VideoPlayerView extends StatelessWidget {
  const VideoPlayerView({
    super.key,
    required this.onVideoViewCreated,
    required this.url,
    this.resizeMode = ResizeMode.fit,
  });

  /// Platform view type name for video player
  static const String _viewType = 'plugins.video/video_player_view';

  final String url;
  final ResizeMode resizeMode;
  final FlutterVideoPlayerViewCreatedCallback onVideoViewCreated;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty || url.trim().isEmpty) {
      return const Center(child: Text('Error: URL cannot be empty'));
    }
    
    // Helper methods for URL detection
    final isHttpUrl = url.startsWith('http://') || url.startsWith('https://');
    final isAssetUrl = url.startsWith('assets/') || url.startsWith('/assets/');
    
    if (!isHttpUrl && !isAssetUrl) {
      return const Center(child: Text('Error: Invalid URL format. Must be HTTP/HTTPS URL or asset path'));
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: <String, dynamic>{
            'resizeMode': resizeMode.name,
            if (isHttpUrl) 'url': url,
            if (isAssetUrl) 'assets': url,
          },
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: <String, dynamic>{
            'resizeMode': resizeMode.name,
            if (isHttpUrl) 'url': url,
            if (isAssetUrl) 'assets': url,
          },
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

// VideoPlayerView Controller class to set url etc
class VideoPlayerViewController {
  VideoPlayerViewController._(int id) : _channel = MethodChannel('$_channelPrefix$id');

  /// Method channel name prefix for video player view controllers
  static const String _channelPrefix = 'plugins.video/video_player_view_';

  final MethodChannel _channel;

  Future<void> setUrl({required String url, ResizeMode resizeMode = ResizeMode.fit}) async =>
      _channel.invokeMethod('setUrl', {'url': url, 'resizeMode': resizeMode.name});

  Future<void> setAssets({required String assets, ResizeMode resizeMode = ResizeMode.fit}) async {
    await _channel.invokeMethod('setAssets', {'assets': assets, 'resizeMode': resizeMode.name});
  }

  Future<void> pause() async => _channel.invokeMethod('pause');

  Future<void> play() async => _channel.invokeMethod('play');

  Future<void> mute() async => _channel.invokeMethod('mute');

  Future<void> unmute() async => _channel.invokeMethod('unmute');

  /// Gets the total duration of the video in seconds
  Future<double> getDuration() async {
    final result = await _channel.invokeMethod('getDuration');
    return (result as double?) ?? 0.0;
  }

  /// Seeks to a specific position in the video
  /// [seconds] - the position to seek to in seconds
  Future<void> seekTo({required double seconds}) async => _channel.invokeMethod('seekTo', {'seconds': seconds});

  StreamController<double>? _positionController;
  Stream<double>? _positionStream;

  StreamController<PlayerStatus>? _statusController;
  Stream<PlayerStatus>? _statusStream;

  /// Flag to track if method call handler is already set
  bool _isHandlerSet = false;

  /// Stream of current playback position in seconds
  Stream<double> get positionStream {
    if (_positionStream != null) {
      return _positionStream!;
    }
    _positionController = StreamController<double>.broadcast();
    _positionStream = _positionController!.stream;

    // Setup handler to receive position updates
    _setupMethodHandler();

    return _positionStream!;
  }

  /// Stream of player status updates
  Stream<PlayerStatus> get statusStream {
    if (_statusStream != null) {
      return _statusStream!;
    }
    _statusController = StreamController<PlayerStatus>.broadcast();
    _statusStream = _statusController!.stream;

    // Setup handler to receive status updates
    _setupMethodHandler();

    return _statusStream!;
  }

  void Function(Object object)? _finishedCallback;

  /// Sets up a method call handler for video player events
  /// Returns the arguments when the video is finished
  void setEventListener(void Function(Object object)? onFinished) {
    _finishedCallback = onFinished;
    _setupMethodHandler();
  }

  void Function(double)? _durationReadyCallback;

  void _setupMethodHandler() {
    // Only set handler once to prevent overwriting and performance issues
    if (!_isHandlerSet) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'positionUpdate') {
          final position = (call.arguments as double?) ?? 0.0;
          _positionController?.add(position);
        } else if (call.method == 'durationReady') {
          final duration = (call.arguments as double?) ?? 0.0;
          if (duration > 0 && _durationReadyCallback != null) {
            _durationReadyCallback!(duration);
          }
        } else if (call.method == 'playerStatus') {
          final statusString = call.arguments as String?;
          if (statusString != null) {
            final status = PlayerStatus.values.firstWhere(
              (e) => e.name == statusString,
              orElse: () => PlayerStatus.idle,
            );
            _statusController?.add(status);
          }
        } else if (call.method == 'finished' && _finishedCallback != null) {
          _finishedCallback!(call.arguments);
        }
      });
      _isHandlerSet = true;
    }
  }

  /// Sets callback for when duration becomes available after video loads
  /// This will be called automatically when native side detects duration is ready
  void onDurationReady(void Function(double duration) callback) {
    _durationReadyCallback = callback;
    _setupMethodHandler();
  }

  /// Disposes the controller and cleans up resources
  Future<void> dispose() async {
    _isHandlerSet = false;
    _channel.setMethodCallHandler(null);
    await _positionController?.close();
    _positionController = null;
    _positionStream = null;
    await _statusController?.close();
    _statusController = null;
    _statusStream = null;
    _finishedCallback = null;
    _durationReadyCallback = null;
  }
}

enum ResizeMode { fit, fill, zoom }

enum PlayerStatus { idle, buffering, ready, ended, playing, paused, error }
