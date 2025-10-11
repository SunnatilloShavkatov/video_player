class PlayerConfiguration {
  const PlayerConfiguration({
    required this.videoUrl,
    required this.title,
    required this.autoText,
    required this.assetPath,
    required this.speedText,
    required this.qualityText,
    required this.lastPosition,
    required this.movieShareLink,
    required this.playVideoFromAsset,
  });

  final String title;
  final String videoUrl;
  final String speedText;
  final int lastPosition;
  final String autoText;
  final String assetPath;
  final String qualityText;
  final String movieShareLink;
  final bool playVideoFromAsset;

  Map<String, dynamic> toMap() => {
    'title': title,
    'videoUrl': videoUrl,
    'autoText': autoText,
    'assetPath': assetPath,
    'speedText': speedText,
    'qualityText': qualityText,
    'lastPosition': lastPosition,
    'movieShareLink': movieShareLink,
    'playVideoFromAsset': playVideoFromAsset,
  };

  @override
  String toString() =>
      'PlayerConfiguration{'
      'videoUrl: $videoUrl, '
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
