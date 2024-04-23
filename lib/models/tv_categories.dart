import 'tv_channel.dart';

class TvCategories {
  const TvCategories({
    required this.id,
    required this.title,
    required this.tvChannels,
  });

  final String id;
  final String title;
  final List<TvChannel> tvChannels;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['tvChannels'] = tvChannels.map((v) => v.toJson()).toList();
    return data;
  }

  @override
  String toString() => 'TvCategories{id: $id, title: $title}';
}
