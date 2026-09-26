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

  /// Paketin şu an geçerli olup olmadığı - mobildeki TEK geçerlilik kuralı.
  /// Backend'deki PackageAssignmentValidity ile birebir aynı: Active &&
  /// (EndDate null || > şimdi) && (RemainingSessions null || > 0). Geçersizse
  /// kullanıcıya gösterilecek neden döner (öncelik: donmuş, süresi dolmuş,
  /// hakkı bitmiş).
  PackageValidity validityAt(DateTime now) {
    if (status != MembershipStatus.active) return PackageValidity.frozen;
    if (endDate != null && !endDate!.isAfter(now)) return PackageValidity.expired;
    if (remainingSessions != null && remainingSessions! <= 0) return PackageValidity.noSessionsLeft;
    return PackageValidity.valid;
  }

  PackageValidity get validity => validityAt(DateTime.now());

  bool get isValid => validity == PackageValidity.valid;
}

enum PackageValidity { valid, frozen, expired, noSessionsLeft }

enum MembershipAvailabilityState { none, invalid, valid }

/// Kullanıcının gym paketleri açısından durumu: hiç paketi yok, var ama
/// hiçbiri geçerli değil (neden [reason]) ya da en az biri geçerli. Backend
/// geçerli paketi olmayan üyeye ders/içerik listesini boş döndüğü için
/// ekranlar boş durumu buna göre seçer.
class MembershipAvailability {
  const MembershipAvailability(this.state, [this.reason]);

  final MembershipAvailabilityState state;
  final PackageValidity? reason;
}

/// [selectedId] verilirse (kullanıcının seçtiği üyelik) geçersizlik nedeni
/// ondan, yoksa listedeki ilk paketten alınır.
MembershipAvailability membershipAvailabilityAt(
  List<MembershipSummary> memberships,
  DateTime now, {
  int? selectedId,
}) {
  if (memberships.isEmpty) return const MembershipAvailability(MembershipAvailabilityState.none);
  if (memberships.any((m) => m.validityAt(now) == PackageValidity.valid)) {
    return const MembershipAvailability(MembershipAvailabilityState.valid);
  }
  final source = memberships.firstWhere((m) => m.id == selectedId, orElse: () => memberships.first);
  return MembershipAvailability(MembershipAvailabilityState.invalid, source.validityAt(now));
}

MembershipAvailability membershipAvailability(List<MembershipSummary> memberships, {int? selectedId}) =>
    membershipAvailabilityAt(memberships, DateTime.now(), selectedId: selectedId);
