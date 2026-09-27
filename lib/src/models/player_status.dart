/// Player status for embedded player view.
///
/// Represents the current state of the video player.
enum PlayerStatus {
  /// Player is idle and no video is loaded.
  idle('idle'),

  /// Player is buffering video data.
  ///
  /// This state occurs when the player is loading video data from the network
  /// or waiting for buffered data to catch up during playback.
  buffering('buffering'),

  /// Player is ready to play.
  ///
  /// Video has loaded successfully and is ready for playback.
  ready('ready'),

  /// Video playback has ended.
  ///
  /// The player has reached the end of the video content.
  ended('ended'),

  /// Video is currently playing.
  playing('playing'),

  /// Video is paused.
  paused('paused'),

  /// Player encountered an error.
  ///
  /// Playback cannot continue due to an error condition.
  error('error');

  new(this.value);

  /// Platform-stable serialization value.
  ///
  /// This value is used for method channel communication with native platforms.
  /// Changing this value would break platform compatibility.
  final String value;

  /// Creates a [PlayerStatus] from its platform value.
  ///
  /// Returns [PlayerStatus.idle] if the value is not recognized,
  /// providing a safe fallback for unknown status values.
  static PlayerStatus fromValue(String value) =>
      PlayerStatus.values.firstWhere((status) => status.value == value, orElse: () => PlayerStatus.idle);
}
