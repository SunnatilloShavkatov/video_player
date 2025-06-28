class DownloadConfiguration {
  const DownloadConfiguration({this.title = '', required this.url});

  final String title;
  final String url;

  Map<String, dynamic> toMap() => {'title': title, 'url': url};

  @override
  String toString() => 'DownloadConfiguration{title: $title, url: $url}';
}
