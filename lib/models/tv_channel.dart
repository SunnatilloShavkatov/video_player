class TvChannel {
  const TvChannel({required this.id, required this.image, required this.name, required this.resolutions});

  final String id;
  final String image;
  final String name;
  final Map<String, String> resolutions;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image, 'resolutions': resolutions};

  @override
  String toString() => 'TvChannel{id: $id, image: $image, name: $name}';
}
