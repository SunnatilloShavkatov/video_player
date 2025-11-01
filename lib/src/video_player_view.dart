import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FlutterVideoPayerViewCreatedCallback = void Function(VideoPlayerViewController controller);

class VideoPlayerView extends StatelessWidget {
  const VideoPlayerView({
    super.key,
    required this.onMapViewCreated,
    required this.url,
    this.resizeMode = ResizeMode.fit,
  });

  /// Platform view type name for video player
  static const String _viewType = 'plugins.video/video_player_view';

  final String url;
  final ResizeMode resizeMode;
  final FlutterVideoPayerViewCreatedCallback onMapViewCreated;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Center(child: Text('Error: URL cannot be empty'));
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'resizeMode': resizeMode.name,
            if (url.contains('http')) 'url': url,
            if (url.contains('assets')) 'assets': url,
          },
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            'resizeMode': resizeMode.name,
            if (url.contains('http')) 'url': url,
            if (url.contains('assets')) 'assets': url,
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
  void _onPlatformViewCreated(int id) => onMapViewCreated(VideoPlayerViewController._(id));
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
    await _channel.invokeMethod('setAssets', {'url': assets, 'resizeMode': resizeMode.name});
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

  StreamController<double>? _positionController;
  Stream<double>? _positionStream;

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

  void Function(Object object)? _finishedCallback;

  /// Sets up a method call handler for video player events
  /// Returns the arguments when the video is finished
  void setEventListener(void Function(Object object)? onFinished) {
    _finishedCallback = onFinished;
    _setupMethodHandler();
  }

  void _setupMethodHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'positionUpdate') {
        final position = (call.arguments as double?) ?? 0.0;
        _positionController?.add(position);
      } else if (call.method == 'finished' && _finishedCallback != null) {
        _finishedCallback!(call.arguments);
      }
    });
  }
}

enum ResizeMode { fit, fill, zoom }
