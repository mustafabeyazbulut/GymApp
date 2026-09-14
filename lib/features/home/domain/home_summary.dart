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

  /// One entry per day, Monday first — true means a class was attended.
  final List<bool> weeklyAttendance;

  int get attendedCount => weeklyAttendance.where((attended) => attended).length;
}
