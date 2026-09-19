enum MembershipStatus { active, frozen }

MembershipStatus membershipStatusFromApi(String value) =>
    value == 'Frozen' ? MembershipStatus.frozen : MembershipStatus.active;

class PaymentHistoryEntry {
  const PaymentHistoryEntry({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class MembershipSummary {
  const MembershipSummary({
    required this.id,
    required this.companyName,
    required this.packageName,
    required this.category,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.sessionCount,
    required this.remainingSessions,
    required this.maxFreezeDays,
    required this.remainingFreezeDays,
  });

  // PackageAssignment'ın kendi id'si - freeze/unfreeze/cancel personel
  // tarafında kaldığından (bkz. membership_repository.dart) burada henüz
  // mutasyon için kullanılmıyor, sadece getPayments(id) için gerekli.
  final int id;
  final String companyName;
  final String packageName;
  // Backend'in ham enum ismi ("GroupClass"/"MartialArts") ya da null (bu
  // paket hiçbir grup dersi için uygun değil) - bkz. MePackageAssignment.category.
  final String? category;
  final MembershipStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double price;
  final int? sessionCount;
  final int? remainingSessions;
  // null = dondurma süresi sınırsız.
  final int? maxFreezeDays;
  final int? remainingFreezeDays;
}
