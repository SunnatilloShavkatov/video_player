class MediaItemDownload {
  const MediaItemDownload({
    required this.url,
    this.percent = 0,
    this.state = 0,
    required this.downloadedBytes,
  });

  static const int STATE_QUEUED = 0;
  static const int STATE_STOPPED = 1;
  static const int STATE_DOWNLOADING = 2;
  static const int STATE_COMPLETED = 3;
  static const int STATE_FAILED = 4;
  static const int STATE_REMOVING = 5;
  static const int STATE_RESTARTING = 7;
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
