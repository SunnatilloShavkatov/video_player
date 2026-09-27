/// Video resize mode for embedded player view.
///
/// Determines how video content fits within the player view bounds.
enum ResizeMode {
  /// Fit video within view bounds while maintaining aspect ratio.
  ///
  /// Video is scaled to fit entirely within the view. Black bars may appear
  /// if aspect ratios don't match.
  fit('fit'),

  /// Fill the entire view, cropping video if necessary.
  ///
  /// Video is scaled to fill the view completely. Parts of the video may be
  /// cropped if aspect ratios don't match.
  fill('fill'),

  /// Zoom video to fill view while maintaining aspect ratio.
  ///
  /// Similar to fill, but ensures the entire video area is visible.
  zoom('zoom');

  new(this.value);

  /// Platform-stable serialization value.
  ///
  /// This value is used for method channel communication with native platforms.
  /// Changing this value would break platform compatibility.
  final String value;

  /// Creates a [ResizeMode] from its platform value.
  ///
  /// Throws [ArgumentError] if the value is not recognized.
  static ResizeMode fromValue(String value) => ResizeMode.values.firstWhere(
    (mode) => mode.value == value,
    orElse: () => throw ArgumentError('Invalid ResizeMode value: $value'),
  );
}
