import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FlutterVideoPayerViewCreatedCallback = void Function(VideoPlayerViewController controller);

class VideoPlayerView extends StatelessWidget {
  /// Platform view type name for video player
  static const String _viewType = 'plugins.video/video_player_view';
  
  const VideoPlayerView({
    super.key,
    required this.onMapViewCreated,
    required this.url,
    this.resizeMode = ResizeMode.fit,
  });

  final FlutterVideoPayerViewCreatedCallback onMapViewCreated;
  final String url;
  final ResizeMode resizeMode;

  @override
  Widget build(BuildContext context) {
    // Validate URL parameter
    if (url.isEmpty) {
      return const Center(
        child: Text('Error: URL cannot be empty'),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            if (url.contains('http')) 'url': url,
            if (url.contains('assets')) 'assets': url,
            'resizeMode': resizeMode.name,
          },
          viewType: _viewType,
          onPlatformViewCreated: _onPlatformViewCreated,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            if (url.contains('http')) 'url': url,
            if (url.contains('assets')) 'assets': url,
            'resizeMode': resizeMode.name,
          },
          viewType: _viewType,
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
  /// Method channel name prefix for video player view controllers
  static const String _channelPrefix = 'plugins.video/video_player_view_';
  
  VideoPlayerViewController._(int id) : _channel = MethodChannel('$_channelPrefix$id');

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

  /// Sets up a method call handler for video player events
  /// Returns the arguments when the video is finished
  void setEventListener(Function(dynamic)? onFinished) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'finished' && onFinished != null) {
        onFinished(call.arguments);
      }
    });
  }
}

enum ResizeMode { fit, fill, zoom }
