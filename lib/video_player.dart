import 'dart:async';
import 'dart:convert';

import 'package:video_player/models/download_configuration.dart';
import 'package:video_player/models/media_item_download.dart';
import 'package:video_player/models/player_configuration.dart';

import 'video_player_platform_interface.dart';

export 'package:video_player/models/download_configuration.dart';
export 'package:video_player/models/media_item_download.dart';
export 'package:video_player/models/movie.dart';
export 'package:video_player/models/player_configuration.dart';
export 'package:video_player/models/programs_info.dart';
export 'package:video_player/models/season.dart';
export 'package:video_player/models/tv_program.dart';

class VideoPlayer {
  factory VideoPlayer() => _instance;

  VideoPlayer._();

  static final VideoPlayer _instance = VideoPlayer._();

  Future<dynamic> playVideo({required PlayerConfiguration playerConfig}) {
    final String jsonStringConfig = jsonEncode(playerConfig.toJson());
    return VideoPlayerPlatform.instance.playVideo(
      playerConfigJsonString: jsonStringConfig,
    );
  }

  Future<dynamic> downloadVideo({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.downloadVideo(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<dynamic> pauseDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.pauseDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<dynamic> resumeDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.resumeDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<bool> isDownloadVideo({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.isDownloadVideo(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<int?> getCurrentProgressDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.getCurrentProgressDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Stream<MediaItemDownload> get currentProgressDownloadAsStream =>
      VideoPlayerPlatform.instance.currentProgressDownloadAsStream();

  Future<int?> getStateDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.getStateDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<int?> getBytesDownloaded({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.getBytesDownloaded(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<int?> getContentBytesDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.getContentBytesDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  Future<dynamic> removeDownload({
    required DownloadConfiguration downloadConfig,
  }) {
    final String jsonStringConfig = jsonEncode(downloadConfig.toJson());
    return VideoPlayerPlatform.instance.removeDownload(
      downloadConfigJsonString: jsonStringConfig,
    );
  }

  void dispose() => VideoPlayerPlatform.instance.dispose();
}
