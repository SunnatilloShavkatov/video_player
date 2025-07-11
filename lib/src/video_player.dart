import 'dart:async';
import 'dart:convert';

import 'package:video_player/src/models/download_configuration.dart';
import 'package:video_player/src/models/media_item_download.dart';
import 'package:video_player/src/models/player_configuration.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

export 'package:video_player/src/models/download_configuration.dart';
export 'package:video_player/src/models/media_item_download.dart';
export 'package:video_player/src/models/player_configuration.dart';

final class VideoPlayer {
  const VideoPlayer._();

  static VideoPlayer get instance => _instance;

  static const VideoPlayer _instance = VideoPlayer._();

  Future<List<int>?> playVideo({required PlayerConfiguration playerConfig}) {
    final String jsonStringConfig = jsonEncode(playerConfig.toMap());
    return VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: jsonStringConfig);
  }

  Future<dynamic> downloadVideo({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.downloadVideo(downloadConfigJsonString: jsonStringConfig);
  }

  Future<dynamic> pauseDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.pauseDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<dynamic> resumeDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.resumeDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<bool> isDownloadVideo({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.isDownloadVideo(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getCurrentProgressDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getCurrentProgressDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Stream<MediaItemDownload> get currentProgressDownloadAsStream =>
      VideoPlayerPlatform.instance.currentProgressDownloadAsStream();

  Future<int?> getStateDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getStateDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getBytesDownloaded({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getBytesDownloaded(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getContentBytesDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getContentBytesDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<dynamic> removeDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.removeDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<void> dispose() async => VideoPlayerPlatform.instance.dispose();
}
