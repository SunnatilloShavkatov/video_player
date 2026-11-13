import 'dart:async';

import 'package:jni/jni.dart';
import 'package:video_player/src/bindings/video_player_api.g.dart';
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/native_video_player.dart';

/// [NativeVideoPlayer] over JNI: Dart calls `VideoPlayerApi` directly, with no method channel. The outcome
/// arrives through an `$async` listener, so Kotlin never blocks on Dart.
class AndroidVideoPlayer extends NativeVideoPlayer {
  new() : super(AndroidVideoPlayerBridge());
}

/// Thin, logic-free JNI calls; see [VideoPlayerBridge].
class AndroidVideoPlayerBridge implements VideoPlayerBridge {
  @override
  Future<List<int>?> playVideo(String playerConfigJson) {
    final Completer<List<int>?> completer = Completer<List<int>?>();
    try {
      final VideoPlayerApi$PlayCallback callback = VideoPlayerApi$PlayCallback.implement(
        $VideoPlayerApi$PlayCallback(
          onFinished: (int positionSeconds, int durationSeconds) {
            if (!completer.isCompleted) {
              completer.complete(<int>[positionSeconds, durationSeconds]);
            }
          },
          onFinished$async: true,
          onCancelled: () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onCancelled$async: true,
          onError: (JString code, JString message) {
            final NativeFailure failure = NativeFailure(
              code: code.toDartString(releaseOriginal: true),
              message: message.toDartString(releaseOriginal: true),
            );
            if (!completer.isCompleted) {
              completer.completeError(failure);
            }
          },
          onError$async: true,
        ),
      );
      handOver(
        callback,
        (VideoPlayerApi$PlayCallback proxy) =>
            using((Arena arena) => VideoPlayerApi.playVideo(playerConfigJson.toJString()..releasedBy(arena), proxy)),
      );
    } on JThrowable catch (e) {
      return Future<List<int>?>.error(NativeFailure(code: 'JNI_ERROR', message: e.toString()));
    }
    return completer.future;
  }

  @override
  Future<void> close() async => VideoPlayerApi.close();
}

/// Passes a Dart-implemented [proxy] to native code and drops Dart's own reference to it. Kotlin keeps the proxy
/// alive for as long as it needs it, and its port closes when Java collects it; without the release every call
/// would pin a JNI global reference until the next Dart GC.
void handOver<T extends JObject>(T proxy, void Function(T proxy) pass) {
  try {
    pass(proxy);
  } finally {
    proxy.release();
  }
}
