import 'package:video_player/models/tv_program.dart';

class ProgramsInfo {
  const ProgramsInfo({required this.day, required this.tvPrograms});

  final String day;
  final List<TvProgram> tvPrograms;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['day'] = day;
    map['tvPrograms'] = tvPrograms.map((v) => v.toJson()).toList();
    return map;
  }

  @override
  String toString() => 'ProgramsInfo{day: $day, tvPrograms: $tvPrograms}';
}
