import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of a video playback session.
///
/// This sealed class represents the outcome when a full-screen video player is closed.
/// It provides type-safe handling of three distinct scenarios:
/// - [PlaybackCompleted]: User watched and closed the video normally
/// - [PlaybackCancelled]: User cancelled playback before video loaded or immediately after opening
/// - [PlaybackFailed]: Playback failed due to an error
///
/// **IMPORTANT: All time values are in SECONDS (int), matching the native platform contract.**
///
/// **Example:**
/// ```
/// final result = await VideoPlayer.instance.playVideo(playerConfig: config);
///
/// switch (result) {
///   case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds):
///     print('Video closed at ${lastPositionSeconds}s of ${durationSeconds}s');
///     saveWatchProgress(lastPositionSeconds);
///   case PlaybackCancelled():
///     print('User cancelled playback');
///   case PlaybackFailed(:final error, :final stackTrace):
///     print('Playback failed: $error');
///     logError(error, stackTrace);
/// }
/// ```
@immutable
sealed class PlaybackResult {
  const PlaybackResult();
}

/// Playback completed successfully and the user closed the video player.
///
/// This result is returned when:
/// - Video loaded successfully
/// - User watched the video (even partially)
/// - User closed the player via the close button or back gesture
///
/// **Position Information (in SECONDS):**
/// - [lastPositionSeconds]: The playback position when the user closed the player, in seconds
/// - [durationSeconds]: The total duration of the video, in seconds
///
/// **Example:**
/// ```
/// if (result case PlaybackCompleted(:final lastPositionSeconds, :final durationSeconds)) {
///   final progressPercent = (lastPositionSeconds / durationSeconds * 100).toInt();
///   print('User watched $progressPercent% of the video');
///
///   // Save resume position for next time
///   await saveProgress(videoId, lastPositionSeconds);
///
///   // Convert to minutes for display
///   final minutes = lastPositionSeconds ~/ 60;
///   final seconds = lastPositionSeconds % 60;
///   print('Stopped at $minutes:${seconds.toString().padLeft(2, '0')}');
/// }
/// ```
final class PlaybackCompleted extends PlaybackResult {
  const PlaybackCompleted({required this.lastPositionSeconds, required this.durationSeconds})
    : assert(lastPositionSeconds >= 0, 'lastPositionSeconds must be non-negative'),
      assert(durationSeconds >= 0, 'durationSeconds must be non-negative'),
      assert(lastPositionSeconds <= durationSeconds, 'lastPositionSeconds cannot exceed durationSeconds');

  /// The playback position when the player was closed, in seconds.
  ///
  /// This value represents where the user stopped watching the video.
  /// Use this to:
  /// - Save watch progress
  /// - Resume playback later from this position
  /// - Calculate watch percentage
  ///
  /// **Unit:** Seconds (int)
  /// **Range:** `0 <= lastPositionSeconds <= durationSeconds`
  final int lastPositionSeconds;

  /// The total duration of the video, in seconds.
  ///
  /// This is the full length of the video content.
  ///
  /// **Unit:** Seconds (int)
  /// **Range:** `>= 0`
  final int durationSeconds;

  @override
  String toString() =>
      'PlaybackCompleted(lastPositionSeconds: $lastPositionSeconds, durationSeconds: $durationSeconds)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackCompleted &&
          runtimeType == other.runtimeType &&
          lastPositionSeconds == other.lastPositionSeconds &&
          durationSeconds == other.durationSeconds;

  @override
  int get hashCode => Object.hash(lastPositionSeconds, durationSeconds);
}

/// Playback was cancelled by the user before meaningful playback occurred.
///
/// This result is returned when:
/// - User closed the player immediately after opening
/// - User dismissed the player during initial loading
/// - User navigated away before video started playing
///
/// **Note:** This is distinct from [PlaybackFailed] - cancellation is a normal
/// user action, not an error condition.
///
/// **Example:**
/// ```
/// if (result is PlaybackCancelled) {
///   print('User cancelled video playback');
///   // Don't save progress or show error
///   // User simply changed their mind
/// }
/// ```
final class PlaybackCancelled extends PlaybackResult {
  const PlaybackCancelled();

  @override
  String toString() => 'PlaybackCancelled()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PlaybackCancelled && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Playback failed due to an error.
///
/// This result is returned when:
/// - Video failed to load (network error, invalid URL, unsupported format)
/// - Playback encountered a fatal error during playback
/// - Native player initialization failed
///
/// **Error Information:**
/// - [error]: The error object (typically a [String], [Exception], or [PlatformException])
/// - [stackTrace]: Optional stack trace for debugging
///
/// **Example:**
/// ```
/// if (result case PlaybackFailed(:final error, :final stackTrace)) {
///   print('Playback failed: $error');
///   if (stackTrace != null) {
///     print('Stack trace: $stackTrace');
///   }
///
///   // Log to error tracking service
///   await errorTracker.recordError(error, stackTrace);
///
///   // Show user-friendly error
///   showDialog(
///     context: context,
///     builder: (_) => AlertDialog(
///       title: Text('Video Unavailable'),
///       content: Text('Unable to play this video. Please try again later.'),
///     ),
///   );
/// }
/// ```
final class PlaybackFailed extends PlaybackResult {
  const PlaybackFailed({required this.error, this.stackTrace});

  /// The error that caused playback to fail.
  ///
  /// This can be:
  /// - A [String] error message from the native platform
  /// - An [Exception] from Dart code
  /// - A [PlatformException] from the method channel
  ///
  /// **Example:**
  /// ```
  /// final errorMessage = error.toString();
  /// if (errorMessage.contains('network')) {
  ///   showNetworkErrorDialog();
  /// } else {
  ///   showGenericErrorDialog();
  /// }
  /// ```
  final Object error;

  /// Optional stack trace for debugging.
  ///
  /// This may be `null` for errors originating from native platforms
  /// that don't provide stack traces.
  final StackTrace? stackTrace;

  @override
  String toString() => 'PlaybackFailed(error: $error, stackTrace: $stackTrace)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackFailed &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => Object.hash(error, stackTrace);
}
