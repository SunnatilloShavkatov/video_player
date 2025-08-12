import 'dart:core';

class PlayerConfiguration {
  const PlayerConfiguration({
    required this.title,
    required this.autoText,
    required this.assetPath,
    required this.speedText,
    required this.qualityText,
    required this.resolutions,
    required this.lastPosition,
    required this.movieShareLink,
    required this.initialResolution,
    required this.playVideoFromAsset,
  });

  final String title;
  final String speedText;
  final int lastPosition;
  final String autoText;
  final String assetPath;
  final String qualityText;
  final String movieShareLink;
  final bool playVideoFromAsset;
  final Map<String, String> resolutions;
  final Map<String, String> initialResolution;

  Map<String, dynamic> toMap() => {
    'title': title,
    'autoText': autoText,
    'assetPath': assetPath,
    'speedText': speedText,
    'qualityText': qualityText,
    'lastPosition': lastPosition,
    'movieShareLink': movieShareLink,
    'playVideoFromAsset': playVideoFromAsset,
    'resolutions': resolutions,
    'initialResolution': initialResolution,
  };

  @override
  String toString() =>
      'PlayerConfiguration{'
      'initialResolution: $initialResolution, '
      'resolutions: $resolutions, '
      'qualityText: $qualityText, '
      'speedText: $speedText, '
      'lastPosition: $lastPosition, '
      'title: $title, '
      'playVideoFromAsset: $playVideoFromAsset, '
      'assetPath: $assetPath, '
      'autoText: $autoText, '
      'movieShareLink: $movieShareLink'
      '}';
}
