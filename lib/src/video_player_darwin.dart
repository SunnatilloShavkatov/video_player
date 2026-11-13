import 'dart:async';

import 'package:objective_c/objective_c.dart' as objc;
import 'package:video_player/src/bindings/video_player_darwin.g.dart';
import 'package:video_player/src/native_bridge.dart';
import 'package:video_player/src/native_video_player.dart';

/// [NativeVideoPlayer] over the Objective-C runtime: Dart calls `VideoPlayerApi` (Swift, `@objc`) directly, with
/// no method channel. Results are listener blocks, which may fire on any thread and are delivered to this isolate.
class DarwinVideoPlayer extends NativeVideoPlayer {
  new() : super(DarwinVideoPlayerBridge());
}

/// Thin, logic-free Objective-C calls; see [VideoPlayerBridge].
class DarwinVideoPlayerBridge implements VideoPlayerBridge {
  @override
  Future<List<int>?> playVideo(String playerConfigJson) {
    final Completer<List<int>?> completer = Completer<List<int>?>();
    try {
      VideoPlayerApi.playVideo(
        playerConfigJson.toNSString(),
        callback: ObjCBlock_ffiVoid_NSInteger_NSInteger_NSString_NSString.listener((
          int positionSeconds,
          int durationSeconds,
          objc.NSString? errorCode,
          objc.NSString? errorMessage,
        ) {
          if (completer.isCompleted) {
            return;
          }
          if (errorCode != null) {
            completer.completeError(
              NativeFailure(code: errorCode.toDartString(), message: errorMessage?.toDartString() ?? ''),
            );
          } else if (positionSeconds < 0) {
            completer.complete();
          } else {
            completer.complete(<int>[positionSeconds, durationSeconds]);
          }
        }),
      );
    } on Object catch (e) {
      return Future<List<int>?>.error(NativeFailure(code: 'OBJC_ERROR', message: e.toString()));
    }
    return completer.future;
  }

  @override
  Future<void> close() {
    final Completer<void> completer = Completer<void>();
    try {
      VideoPlayerApi.close(
        ObjCBlock_ffiVoid.listener(() {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }),
      );
    } on Object catch (e) {
      return Future<void>.error(NativeFailure(code: 'OBJC_ERROR', message: e.toString()));
    }
    return completer.future;
  }
}
