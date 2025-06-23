import 'package:video_player/models/tv_program.dart';

class ProgramsInfo {
  const ProgramsInfo({required this.day, required this.tvPrograms});

  final String day;
  final List<TvProgram> tvPrograms;

  Map<String, dynamic> toMap() => {'day': day, 'tvPrograms': tvPrograms.map((v) => v.toMap()).toList()};

  @override
  String toString() => 'ProgramsInfo{day: $day, tvPrograms: $tvPrograms}';
}
