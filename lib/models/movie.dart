class Movie {
  Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.duration,
    required this.resolutions,
  });

  final String id;
  final String title;
  final String description;
  final String image;
  final int duration;
  final Map<String, String> resolutions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['description'] = description;
    map['image'] = image;
    map['duration'] = duration;
    map['resolutions'] = resolutions;
    return map;
  }

  @override
  String toString() =>
      'Movie{id: $id, title: $title, description: $description, image: $image, duration: $duration, resolutions: $resolutions}';
}
