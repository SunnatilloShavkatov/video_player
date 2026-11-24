import 'package:video_player/src/unsupported_video_player.dart';
import 'package:video_player/src/video_player_platform_interface.dart';

/// Used where `dart:ffi` is unavailable (web), so the JNI and Objective-C bindings are never compiled there.
VideoPlayerPlatform createNativeVideoPlayer() => UnsupportedVideoPlayer();
