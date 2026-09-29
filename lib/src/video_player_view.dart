import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/src/models/player_status.dart';
import 'package:video_player/src/models/resize_mode.dart';
import 'package:video_player/src/utils/url_validator.dart';

export 'package:video_player/src/models/player_status.dart';
export 'package:video_player/src/models/resize_mode.dart';

// The controller is a part so the widget can use its private constructor
// without exposing one in the public API.
part 'video_player_view_controller.dart';

typedef FlutterVideoPlayerViewCreatedCallback = void Function(VideoPlayerViewController controller);

class VideoPlayerView extends StatelessWidget {
  const new({
    super.key,
    required this.url,
    required this.onVideoViewCreated,
    this.resizeMode = ResizeMode.fit,
    this.keyRequestHeaders = const {},
  });

  /// Platform view type name for video player
  static const String _viewType = 'plugins.video/video_player_view';

  final String url;
  final ResizeMode resizeMode;
  final FlutterVideoPlayerViewCreatedCallback onVideoViewCreated;

  /// HTTP headers sent **only** with HLS AES-128 key requests (the `URI` of
  /// `#EXT-X-KEY`), e.g. `{'Authorization': 'Bearer $token'}`. Playlist and
  /// segment requests never carry them.
  final Map<String, String> keyRequestHeaders;

  Map<String, dynamic> get _creationParams => <String, dynamic>{
    'url': url,
    'resizeMode': resizeMode.value,
    'keyRequestHeaders': keyRequestHeaders,
  };

  @override
  Widget build(BuildContext context) {
    if (UrlValidator.instance.isNotValidHttpsUrl(url)) {
      return const Center(child: Text('Error: Invalid URL format. Must be HTTPS URL'));
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: _creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: _creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.macOS:
        return AppKitView(
          viewType: _viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: _creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.fuchsia:
        return Text('$defaultTargetPlatform is not yet supported by the video_player plugin');
      case TargetPlatform.windows:
        return Text('$defaultTargetPlatform is not yet supported by the video_player plugin');
      case TargetPlatform.linux:
        return Text('$defaultTargetPlatform is not yet supported by the video_player plugin');
    }
  }

  // Callback method when platform view is created
  void _onPlatformViewCreated(int id) => onVideoViewCreated(VideoPlayerViewController._(id));
}
