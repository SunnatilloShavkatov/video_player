import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_player/src/models/playback_result.dart';
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
  Future<PlaybackResult> playVideo({required String playerConfigJsonString}) async {
    try {
      final result = await methodChannel.invokeMethod<List<Object?>>('playVideo', {
        'playerConfigJsonString': playerConfigJsonString,
      });

      // Translate platform response into PlaybackResult
      if (result == null) {
        // null response indicates user cancelled playback
        return const PlaybackCancelled();
      }

      // Platform returns [lastPositionSeconds, durationSeconds] as integers (in SECONDS)
      if (result.length != 2) {
        return PlaybackFailed(
          error: 'Invalid platform response: expected 2 elements, got ${result.length}',
        );
      }

      final lastPositionSeconds = (result[0] ?? 0) as int;
      final durationSeconds = (result[1] ?? 1) as int;

      // Return as-is (platform already provides seconds)
      return PlaybackCompleted(
        lastPositionSeconds: lastPositionSeconds,
        durationSeconds: durationSeconds,
      );
    } on PlatformException catch (error, stackTrace) {
      logMessage('playVideo failed with PlatformException', error: error, stackTrace: stackTrace);
      return PlaybackFailed(error: error, stackTrace: stackTrace);
    } catch (error, stackTrace) {
      logMessage('playVideo failed', error: error, stackTrace: stackTrace);
      return PlaybackFailed(error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> close() async {
    try {
      await methodChannel.invokeMethod<void>('close');
    } catch (error, stackTrace) {
      logMessage('close failed', error: error, stackTrace: stackTrace);
    }
  }
}
