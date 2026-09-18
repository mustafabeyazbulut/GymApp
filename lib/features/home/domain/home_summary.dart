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

  /// Her gün için bir (gün etiketi, katıldı mı) çifti, Pazartesi ilk sırada.
  /// Etiket doğrudan kendi değeriyle eşleştirilir — bilinçli olarak
  /// pozisyona göre eşleştirilen ayrı, aynı uzunlukta bir liste değil —
  /// böylece farklı bir sırada katılım döndüren gerçek bir backend, UI'ın
  /// yanında render ettiği gün etiketleriyle asla sessizce senkronizasyonunu
  /// kaybedemez.
  final List<(String, bool)> weeklyAttendance;

  int get attendedCount => weeklyAttendance.where((day) => day.$2).length;
}
