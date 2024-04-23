class TvProgram {
  const TvProgram({
    required this.scheduledTime,
    required this.programTitle,
  });

  final String scheduledTime;
  final String programTitle;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['scheduledTime'] = scheduledTime;
    map['programTitle'] = programTitle;
    return map;
  }

  @override
  String toString() =>
      'TvProgram{scheduledTime: $scheduledTime, programTitle: $programTitle}';
}
