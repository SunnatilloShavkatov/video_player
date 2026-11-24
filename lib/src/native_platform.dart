import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:video_player/src/unsupported_video_player.dart';
import 'package:video_player/src/video_player_android.dart';
import 'package:video_player/src/video_player_darwin.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

/// The native player for the current platform: JNI on Android, the Objective-C runtime on iOS and macOS.
VideoPlayerPlatform createNativeVideoPlayer() => switch (defaultTargetPlatform) {
  TargetPlatform.android => AndroidVideoPlayer(),
  TargetPlatform.iOS || TargetPlatform.macOS => DarwinVideoPlayer(),
  TargetPlatform.fuchsia || TargetPlatform.linux || TargetPlatform.windows => UnsupportedVideoPlayer(),
};
