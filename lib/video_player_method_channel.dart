import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/models/media_item_download.dart';

import 'video_player_platform_interface.dart';

/// An implementation of [VideoPlayerPlatform] that uses method channels.
class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_player');
  final StreamController<MediaItemDownload> _streamController = StreamController<MediaItemDownload>.broadcast();

  @override
  Future<List<int>?> playVideo({required String playerConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<List<Object?>>(
      'playVideo',
      <String, dynamic>{'playerConfigJsonString': playerConfigJsonString},
    );
    if (res == null) return null;
    final List<int> list = res.map((e) => (e ?? 1) as int).toList();
    return list;
  }

  @override
  Future downloadVideo({required String downloadConfigJsonString}) async {
    await methodChannel.invokeMethod(
      'downloadVideo',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
  }

  @override
  Future pauseDownload({required String downloadConfigJsonString}) async {
    await methodChannel.invokeMethod(
      'pauseDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
  }

  @override
  Future resumeDownload({required String downloadConfigJsonString}) async {
    await methodChannel.invokeMethod(
      'resumeDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
  }

  @override
  Future<bool> isDownloadVideo({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<bool?>(
      'checkIsDownloadedVideo',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
    return res ?? false;
  }

  @override
  Future<int?> getCurrentProgressDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>(
      'getCurrentProgressDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
    return res;
  }

  @override
  Stream<MediaItemDownload> currentProgressDownloadAsStream() {
    methodChannel.setMethodCallHandler(
      (call) async {
        if (call.method == 'percent') {
          final json = call.arguments as String;
          final decode = jsonDecode(json);
          _streamController.add(
            MediaItemDownload(
              url: decode['url'],
              percent: decode['percent'],
              state: decode['state'],
              downloadedBytes: decode['downloadedBytes'],
            ),
          );
        }
      },
    );
    return _streamController.stream;
  }

  @override
  Future<int?> getStateDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>(
      'getStateDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
    return res;
  }

  @override
  Future<int?> getBytesDownloaded({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>(
      'getBytesDownloaded',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
    return res;
  }

  @override
  Future<int?> getContentBytesDownload({required String downloadConfigJsonString}) async {
    final res = await methodChannel.invokeMethod<int>(
      'getContentBytesDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
    return res;
  }

  @override
  Future removeDownload({required String downloadConfigJsonString}) async {
    await methodChannel.invokeMethod(
      'removeDownload',
      <String, dynamic>{'downloadConfigJsonString': downloadConfigJsonString},
    );
  }

  @override
  void dispose() {
    _streamController.onCancel!();
  }

  @override
  Future<int?> getPercentDownload({required String downloadConfigJsonString}) => Future.value(0);
}
