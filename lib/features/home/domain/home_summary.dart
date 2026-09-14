class HomeSummary {
  const HomeSummary({
    required this.greetingName,
    required this.activePackageName,
    required this.daysLeft,
    required this.nextClassName,
    required this.nextClassTime,
    required this.nextClassTrainer,
    required this.weeklyAttendance,
  });

  final String greetingName;
  final String activePackageName;
  final int daysLeft;
  final String nextClassName;
  final String nextClassTime;
  final String nextClassTrainer;

  /// One (day label, attended) pair per day, Monday first. The label is
  /// paired directly with its value — deliberately not a separate
  /// same-length list zipped by position — so a real backend returning
  /// attendance in a different order can never silently desync from the
  /// day labels the UI renders next to it.
  final List<(String, bool)> weeklyAttendance;

  int get attendedCount => weeklyAttendance.where((day) => day.$2).length;
}
