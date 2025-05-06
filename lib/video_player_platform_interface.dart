import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player/models/media_item_download.dart';

import 'package:video_player/video_player_method_channel.dart';

abstract class VideoPlayerPlatform extends PlatformInterface {
  /// Constructs a VideoPlayerPlatform.
  VideoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoPlayerPlatform _instance = MethodChannelVideoPlayer();

  /// The default instance of [VideoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoPlayer].
  static VideoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoPlayerPlatform] when
  /// they register themselves.
  static set instance(VideoPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<int>?> playVideo({required String playerConfigJsonString});

  Future<void> downloadVideo({required String downloadConfigJsonString});

  Future<void> pauseDownload({required String downloadConfigJsonString});

  Future<void> resumeDownload({required String downloadConfigJsonString});

  Future<bool> isDownloadVideo({required String downloadConfigJsonString});

  Future<int?> getCurrentProgressDownload({required String downloadConfigJsonString});

  Stream<MediaItemDownload> currentProgressDownloadAsStream();

  Future<int?> getStateDownload({required String downloadConfigJsonString});

  Future<int?> getPercentDownload({required String downloadConfigJsonString});

  Future<int?> getBytesDownloaded({required String downloadConfigJsonString});

  Future<int?> getContentBytesDownload({required String downloadConfigJsonString});

  Future<void> removeDownload({required String downloadConfigJsonString});

  Future<void> dispose();
}
