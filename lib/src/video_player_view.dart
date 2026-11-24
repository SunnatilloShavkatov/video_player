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

/// Owns the [VideoPlayerViewController] it creates: the controller is disposed when the view leaves the tree, and
/// a rebuild with a different [url], [resizeMode], [keyRequestHeaders] or [keyRequestHosts] loads the new source.
class VideoPlayerView extends StatefulWidget {
  const new({
    super.key,
    required this.url,
    required this.onVideoViewCreated,
    this.resizeMode = ResizeMode.fit,
    this.keyRequestHeaders = const {},
    this.keyRequestHosts = const [],
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

  /// Extra hosts, besides the playlist's own host, that may receive
  /// [keyRequestHeaders]. See `PlayerConfiguration.keyRequestHosts`.
  final List<String> keyRequestHosts;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerViewController? _controller;

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !_sourceChanged(oldWidget)) {
      return;
    }
    if (UrlValidator.instance.isNotValidHttpsUrl(widget.url)) {
      return;
    }
    unawaited(
      controller
          .setUrl(
            url: widget.url,
            resizeMode: widget.resizeMode,
            keyRequestHeaders: widget.keyRequestHeaders,
            keyRequestHosts: widget.keyRequestHosts,
          )
          .catchError((Object _) {}, test: (e) => e is StateError || e is PlatformException),
    );
  }

  bool _sourceChanged(VideoPlayerView old) =>
      old.url != widget.url ||
      old.resizeMode != widget.resizeMode ||
      !mapEquals(old.keyRequestHeaders, widget.keyRequestHeaders) ||
      !listEquals(old.keyRequestHosts, widget.keyRequestHosts);

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Text('Web is not yet supported by the video_player plugin');
    }
    if (UrlValidator.instance.isNotValidHttpsUrl(widget.url)) {
      return const Center(child: Text('Error: Invalid URL format. Must be HTTPS URL'));
    }
    final creationParams = <String, dynamic>{
      'url': widget.url,
      'resizeMode': widget.resizeMode.value,
      'keyRequestHeaders': widget.keyRequestHeaders,
      'keyRequestHosts': widget.keyRequestHosts,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: VideoPlayerView._viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: VideoPlayerView._viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.macOS:
        return AppKitView(
          viewType: VideoPlayerView._viewType,
          layoutDirection: TextDirection.ltr,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          creationParams: creationParams,
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return Text('$defaultTargetPlatform is not yet supported by the video_player plugin');
    }
  }

  void _onPlatformViewCreated(int id) {
    unawaited(_controller?.dispose());
    final controller = VideoPlayerViewController._(id);
    _controller = controller;
    widget.onVideoViewCreated(controller);
  }
}
