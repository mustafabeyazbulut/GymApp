class NextReservation {
  const NextReservation({required this.trainerName, required this.scheduledAt});

  final String trainerName;
  final DateTime scheduledAt;
}

class HomeSummary {
  const HomeSummary({
    required this.companyName,
    required this.packageName,
    required this.endDate,
    required this.nextReservation,
    required this.weeklyAttendance,
  });

  final String companyName;
  final String packageName;
  // null = süresiz paket (ör. session-based bir paket, EndDate hiç set
  // edilmemiş olabilir) - bkz. GymAppApi'nin PackageAssignment.EndDate'i.
  final DateTime? endDate;
  final NextReservation? nextReservation;

  /// Son 7 gün için bir (gün, o gün check-in var mı) çifti, en eskisi ilk
  /// sırada, bugün son sırada.
  final List<(DateTime, bool)> weeklyAttendance;

  int? get daysLeft => endDate?.difference(DateTime.now()).inDays;

  int get attendedCount => weeklyAttendance.where((day) => day.$2).length;
}
