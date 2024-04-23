class DownloadConfiguration {
  const DownloadConfiguration({
    this.title = '',
    required this.url,
  });

  final String title;
  final String url;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['url'] = url;
    return map;
  }

  @override
  String toString() => 'DownloadConfiguration{title: $title, url: $url}';
}
