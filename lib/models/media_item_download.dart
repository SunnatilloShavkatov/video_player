class MediaItemDownload {
  const MediaItemDownload({
    required this.url,
    this.percent = 0,
    this.state = 0,
    required this.downloadedBytes,
  });

  static const int stateQueued = 0;
  static const int stateStopped = 1;
  static const int stateDownloading = 2;
  static const int stateCompleted = 3;
  static const int stateFailed = 4;
  static const int stateRemoving = 5;
  static const int stateRestating = 7;
  final String url;
  final int percent;
  final int state;
  final int downloadedBytes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['percent'] = percent;
    return map;
  }

  @override
  String toString() =>
      'MediaItemDownload{url: $url, percent: $percent,  state: $state}';
}
