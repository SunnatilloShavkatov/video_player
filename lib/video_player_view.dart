import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef FlutterVideoPayerViewCreatedCallback = void Function(
  VideoPlayerViewController controller,
);

class VideoPlayerView extends StatelessWidget {
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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          layoutDirection: TextDirection.ltr,
          creationParams: <String, dynamic>{
            if (url.contains('http')) 'url': url,
            if (url.contains('assets')) 'assets': url,
            'resizeMode': resizeMode.name,
          },
          viewType: 'plugins.udevs/video_player_view',
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
          viewType: 'plugins.udevs/video_player_view',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        return Text(
          '$defaultTargetPlatform is not yet supported by the web_view plugin',
        );
    }
  }

  // Callback method when platform view is created
  void _onPlatformViewCreated(int id) =>
      onMapViewCreated(VideoPlayerViewController._(id));
}

// VideoPlayerView Controller class to set url etc
class VideoPlayerViewController {
  VideoPlayerViewController._(int id)
      : _channel = MethodChannel('plugins.udevs/video_player_view_$id');

  final MethodChannel _channel;

  Future<void> setUrl({
    required String url,
    ResizeMode resizeMode = ResizeMode.fit,
  }) async =>
      _channel.invokeMethod(
        'setUrl',
        {
          'url': url,
          'resizeMode': resizeMode.name,
        },
      );

  Future<void> setAssets({
    required String assets,
    ResizeMode resizeMode = ResizeMode.fit,
  }) async {
    await _channel.invokeMethod(
      'setAssets',
      {
        'url': assets,
        'resizeMode': resizeMode.name,
      },
    );
  }

  Future<void> pause() async => _channel.invokeMethod('pause');

  Future<void> play() async => _channel.invokeMethod('play');

  Future<void> mute() async => _channel.invokeMethod('mute');

  Future<void> unMute() async => _channel.invokeMethod('un-mute');

  Stream<dynamic>? listener() {
    _channel.setMethodCallHandler(
      (call) async {
        if (call.method == 'finished') {
          return call.arguments;
        }
      },
    );
    return null;
  }
}

enum ResizeMode { fit, fill, zoom }
