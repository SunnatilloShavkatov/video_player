class TvProgram {
  const TvProgram({required this.scheduledTime, required this.programTitle});

  final String scheduledTime;
  final String programTitle;

  Map<String, dynamic> toMap() => {'programTitle': programTitle, 'scheduledTime': scheduledTime};

  @override
  String toString() => 'TvProgram{scheduledTime: $scheduledTime, programTitle: $programTitle}';
}
