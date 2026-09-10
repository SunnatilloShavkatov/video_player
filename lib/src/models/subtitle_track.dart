import 'package:flutter/cupertino.dart';

/// Model representing a subtitle track for video playback.
///
/// Contains the metadata and remote URL for a sidecar subtitle file (e.g., WebVTT).
@immutable
class SubtitleTrack {

  /// Creates a new [SubtitleTrack] instance.
  const new({
    required this.id,
    required this.label,
    required this.lang,
    this.isDefault = false,
    required this.url,
  });

  /// Creates a [SubtitleTrack] from a JSON-compatible map.
  factory fromMap(Map<String, dynamic> map) => SubtitleTrack(
      id: (map['id'] as num?)?.toInt() ?? 0,
      label: (map['label'] as String?) ?? '',
      lang: (map['lang'] as String?) ?? '',
      isDefault: (map['is_default'] as bool?) ?? (map['isDefault'] as bool?) ?? false,
      url: (map['url'] as String?) ?? '',
    );
  /// Unique identifier for this subtitle track.
  final int id;

  /// Human-readable label for the subtitle (e.g. 'English', 'Spanish').
  final String label;

  /// Language code for the subtitle (e.g. 'en', 'es', 'uz').
  final String lang;

  /// Whether this subtitle track should be selected by default.
  final bool isDefault;

  /// HTTPS URL pointing to the WebVTT file.
  final String url;

  /// Converts this [SubtitleTrack] to a JSON-compatible map.
  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'lang': lang,
    'is_default': isDefault,
    'url': url,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubtitleTrack &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          lang == other.lang &&
          isDefault == other.isDefault &&
          url == other.url;

  @override
  int get hashCode => Object.hash(id, label, lang, isDefault, url);

  @override
  String toString() =>
      'SubtitleTrack(id: $id, label: $label, lang: $lang, isDefault: $isDefault, url: $url)';
}
