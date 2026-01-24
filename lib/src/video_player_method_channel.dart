import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/src/utils/log_message.dart';

import 'package:video_player/src/video_player_platform_interface.dart';

/// An implementation of [VideoPlayerPlatform] that uses method channels.
class MethodChannelVideoPlayer extends VideoPlayerPlatform {
  /// Method channel name for video player communication
  static const String _channelName = 'video_player';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(_channelName);

  @override
  Future<List<int>?> playVideo({required String playerConfigJsonString}) async {
    try {
      final res = await methodChannel.invokeMethod<List<Object?>>('playVideo', {
        'playerConfigJsonString': playerConfigJsonString,
      });
      if (res == null) {
        return null;
      }
      final List<int> list = res.map((e) => (e ?? 1) as int).toList();
      return list;
    } catch (error, stackTrace) {
      logMessage('playVideo failed', error: error, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> close() async {
    try {
      await methodChannel.invokeMethod<void>('close');
    } catch (error, stackTrace) {
      logMessage('playVideo failed', error: error, stackTrace: stackTrace);
    }
  }
}
