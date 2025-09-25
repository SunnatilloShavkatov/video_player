import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/src/models/media_item_download.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

/// An implementation of [VideoPlayerPlatform] that uses method channels.
class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  /// Method channel name for video player communication
  static const String _channelName = 'video_player';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_channelName);
  final StreamController<MediaItemDownload> _streamController = StreamController<MediaItemDownload>.broadcast();

  /// Timer for debouncing progress updates
  Timer? _debounceTimer;
  MediaItemDownload? _lastProgress;

  @override
  Future<List<int>?> playVideo({required String playerConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<List<Object?>>('playVideo', {
      'playerConfigJsonString': playerConfigJsonString,
    });
    if (res == null) {
      return null;
    }
    final List<int> list = res.map((e) => (e ?? 1) as int).toList();
    return list;
  }

  @override
  Future<bool> downloadVideo({required String downloadConfigJsonString}) async {
    try {
      await methodChannel.invokeMethod('downloadVideo', {'downloadConfigJsonString': downloadConfigJsonString});
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<bool> pauseDownload({required String downloadConfigJsonString}) async {
    try {
      await methodChannel.invokeMethod('pauseDownload', {'downloadConfigJsonString': downloadConfigJsonString});
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resumeDownload({required String downloadConfigJsonString}) async {
    try {
      await methodChannel.invokeMethod('resumeDownload', {'downloadConfigJsonString': downloadConfigJsonString});
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isDownloadVideo({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<bool?>('isDownloadVideo', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res ?? false;
  }

  @override
  Future<int?> getCurrentProgressDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>('getCurrentProgressDownload', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res;
  }

  @override
  Stream<MediaItemDownload> currentProgressDownloadAsStream() {
    methodChannel.setMethodCallHandler((call) async {
      if (call.method == 'percent') {
        final json = call.arguments as String;
        final Map<dynamic, dynamic> decode = jsonDecode(json);
        final progress = MediaItemDownload(
          url: decode['url'],
          state: decode['state'],
          percent: decode['percent'],
          downloadedBytes: decode['downloadedBytes'],
        );

        // Debounce progress updates to avoid excessive UI updates
        _lastProgress = progress;
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (_lastProgress != null) {
            _streamController.add(_lastProgress!);
          }
        });
      }
    });
    return _streamController.stream;
  }

  @override
  Future<int?> getStateDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>('getStateDownload', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res;
  }

  @override
  Future<int?> getBytesDownloaded({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>('getBytesDownloaded', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res;
  }

  @override
  Future<int?> getContentBytesDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>('getContentBytesDownload', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res;
  }

  @override
  Future<bool> removeDownload({required String downloadConfigJsonString}) async {
    try {
      await methodChannel.invokeMethod('removeDownload', {'downloadConfigJsonString': downloadConfigJsonString});
      return true;
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _debounceTimer?.cancel();
    await _streamController.close();
  }

  @override
  Future<int?> getPercentDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>('getPercentDownload', {
      'downloadConfigJsonString': downloadConfigJsonString,
    });
    return res;
  }
}
