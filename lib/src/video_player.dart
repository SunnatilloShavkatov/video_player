import 'dart:async';
import 'dart:convert';

import 'package:video_player/src/models/download_configuration.dart';
import 'package:video_player/src/models/media_item_download.dart';
import 'package:video_player/src/models/player_configuration.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

export 'package:video_player/src/models/download_configuration.dart';
export 'package:video_player/src/models/media_item_download.dart';
export 'package:video_player/src/models/player_configuration.dart';

/// Main video player class that provides video playback and download functionality.
///
/// This class follows the singleton pattern and provides methods for:
/// - Playing videos with custom configurations
/// - Downloading videos for offline playback
/// - Managing download states (pause, resume, remove)
/// - Tracking download progress
final class VideoPlayer {
  const VideoPlayer._();

  /// Returns the singleton instance of VideoPlayer
  static VideoPlayer get instance => _instance;

  static const VideoPlayer _instance = VideoPlayer._();

  /// Helper method to encode configuration to JSON string
  String _encodeConfig(Map<String, dynamic> config) => jsonEncode(config);

  /// Plays a video with the given player configuration.
  ///
  /// Returns a list of integers representing playback time information,
  /// or null if playback fails.
  Future<List<int>?> playVideo({required PlayerConfiguration playerConfig}) {
    final String jsonStringConfig = _encodeConfig(playerConfig.toMap());
    return VideoPlayerPlatform.instance.playVideo(playerConfigJsonString: jsonStringConfig);
  }

  /// Downloads a video for offline playback.
  ///
  /// Returns true if download was successfully started, false otherwise.
  Future<bool> downloadVideo({required DownloadConfiguration downloadConfig}) {
    if (!downloadConfig.isValid) {
      throw ArgumentError('Invalid download configuration: URL is empty or malformed');
    }
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.downloadVideo(downloadConfigJsonString: jsonStringConfig);
  }

  Future<bool> pauseDownload({required DownloadConfiguration downloadConfig}) {
    if (!downloadConfig.isValid) {
      throw ArgumentError('Invalid download configuration: URL is empty or malformed');
    }
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.pauseDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<bool> resumeDownload({required DownloadConfiguration downloadConfig}) {
    if (!downloadConfig.isValid) {
      throw ArgumentError('Invalid download configuration: URL is empty or malformed');
    }
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.resumeDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<bool> isDownloadVideo({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.isDownloadVideo(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getCurrentProgressDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getCurrentProgressDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Stream<MediaItemDownload> get currentProgressDownloadAsStream =>
      VideoPlayerPlatform.instance.currentProgressDownloadAsStream();

  Future<int?> getStateDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getStateDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getBytesDownloaded({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getBytesDownloaded(downloadConfigJsonString: jsonStringConfig);
  }

  Future<int?> getContentBytesDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.getContentBytesDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<bool> removeDownload({required DownloadConfiguration downloadConfig}) {
    final String jsonStringConfig = _encodeConfig(downloadConfig.toMap());
    return VideoPlayerPlatform.instance.removeDownload(downloadConfigJsonString: jsonStringConfig);
  }

  Future<void> dispose() async => VideoPlayerPlatform.instance.dispose();
}
