class TvChannel {
  const TvChannel({
    required this.id,
    required this.image,
    required this.name,
    required this.resolutions,
  });

  final String id;
  final String image;
  final String name;
  final Map<String, String> resolutions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['image'] = image;
    map['name'] = name;
    map['resolutions'] = resolutions;
    return map;
  }
}
