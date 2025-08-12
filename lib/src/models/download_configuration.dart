/// Configuration for video downloads
class DownloadConfiguration {
  const DownloadConfiguration({this.title = '', required this.url});

  final String title;
  final String url;

  /// Validates the configuration
  bool get isValid => url.isNotEmpty && Uri.tryParse(url) != null;

  Map<String, dynamic> toMap() => {'title': title, 'url': url};

  @override
  String toString() => 'DownloadConfiguration{title: $title, url: $url}';
}
