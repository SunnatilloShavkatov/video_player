/// Represents a downloadable media item with progress information.
class MediaItemDownload {
  const MediaItemDownload({required this.url, this.percent = 0, this.state = 0, required this.downloadedBytes});

  /// Download state constants
  static const int stateQueued = 0;
  static const int stateStopped = 1;
  static const int stateDownloading = 2;
  static const int stateCompleted = 3;
  static const int stateFailed = 4;
  static const int stateRemoving = 5;
  static const int stateRestarting = 7; // Fixed typo from 'stateRestating'
  
  final String url;
  final int percent;
  final int state;
  final int downloadedBytes;

  /// Returns true if the download is currently in progress
  bool get isDownloading => state == stateDownloading;
  
  /// Returns true if the download is completed
  bool get isCompleted => state == stateCompleted;
  
  /// Returns true if the download has failed
  bool get hasFailed => state == stateFailed;

  Map<String, dynamic> toMap() => {'url': url, 'percent': percent};

  @override
  String toString() => 'MediaItemDownload{url: $url, percent: $percent,  state: $state}';
}
