/// A native call that completed with an error: the `(code, message)` the native side reported.
class NativeFailure implements Exception {
  const new({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'NativeFailure(code: $code, message: $message)';
}

/// The native `VideoPlayerApi`, one method each. Implemented over JNI on Android and over the Objective-C runtime
/// on iOS and macOS; tests install a fake. Positions are in SECONDS.
abstract interface class VideoPlayerBridge {
  /// Completes with `[lastPositionSeconds, durationSeconds]`, with `null` when the session ended without a
  /// position (cancelled), or fails with [NativeFailure].
  Future<List<int>?> playVideo(String playerConfigJson);

  /// Closes the active player, if any, and completes once native has done so.
  Future<void> close();
}
