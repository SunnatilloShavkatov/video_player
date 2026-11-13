# Dart reaches the facade only through JNI (lib/src/bindings), so R8 must keep its name and members.
-keep class uz.plugin.video_player.VideoPlayerApi { *; }
-keep interface uz.plugin.video_player.VideoPlayerApi$* { *; }
