import 'package:video_player/models/movie.dart';

class Season {
  const Season({required this.title, required this.movies});

  final String title;
  final List<Movie> movies;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['title'] = title;
    map['movies'] = movies.map((v) => v.toJson()).toList();
    return map;
  }

  @override
  String toString() => 'Season{title: $title, movies: $movies}';
}
