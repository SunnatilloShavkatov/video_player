import 'package:video_player/models/movie.dart';

class Season {
  const Season({required this.title, required this.movies});

  final String title;
  final List<Movie> movies;

  Map<String, dynamic> toMap() => {'title': title, 'movies': movies.map((v) => v.toJson()).toList()};

  @override
  String toString() => 'Season{title: $title, movies: $movies}';
}
