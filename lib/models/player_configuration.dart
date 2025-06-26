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
    required this.showController,
    required this.initialResolution,
    required this.playVideoFromAsset,
  });

  final String title;
  final String speedText;
  final int lastPosition;
  final String autoText;
  final String assetPath;
  final String qualityText;
  final bool showController;
  final String movieShareLink;
  final bool playVideoFromAsset;
  final Map<String, String> resolutions;
  final Map<String, String> initialResolution;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['initialResolution'] = initialResolution;
    map['resolutions'] = resolutions;
    map['qualityText'] = qualityText;
    map['speedText'] = speedText;
    map['lastPosition'] = lastPosition;
    map['title'] = title;
    map['showController'] = showController;
    map['playVideoFromAsset'] = playVideoFromAsset;
    map['assetPath'] = assetPath;
    map['autoText'] = autoText;
    map['movieShareLink'] = movieShareLink;
    return map;
  }

  @override
  String toString() =>
      'PlayerConfiguration{'
      'initialResolution: $initialResolution, '
      'resolutions: $resolutions, '
      'qualityText: $qualityText, '
      'speedText: $speedText, '
      'lastPosition: $lastPosition, '
      'title: $title, '
      'showController: $showController, '
      'playVideoFromAsset: $playVideoFromAsset, '
      'assetPath: $assetPath, '
      'autoText: $autoText '
      'movieShareLink: $movieShareLink, '
      '}';
}
