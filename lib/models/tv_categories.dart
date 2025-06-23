import 'package:video_player/models/tv_channel.dart';

class TvCategories {
  const TvCategories({required this.id, required this.title, required this.tvChannels});

  final String id;
  final String title;
  final List<TvChannel> tvChannels;

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'tvChannels': tvChannels.map((v) => v.toJson()).toList()};

  @override
  String toString() => 'TvCategories{id: $id, title: $title}';
}
