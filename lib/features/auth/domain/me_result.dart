class MeAssignment {
  const MeAssignment({
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.role,
  });

  factory MeAssignment.fromJson(Map<String, dynamic> json) => MeAssignment(
        companyId: json['companyId'] as int?,
        companyName: json['companyName'] as String?,
        branchId: json['branchId'] as int?,
        role: json['role'] as String,
      );

  // Platform genelinde bir atama için null olur (ör. SuperAdmin); tek bir şirkete bağlı değildir.
  final int? companyId;
  final String? companyName;
  final int? branchId;
  final String role;
}

class MePackageAssignment {
  const MePackageAssignment({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.packageId,
    required this.packageName,
    required this.category,
    required this.price,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.sessionCount,
    required this.remainingSessions,
    required this.maxFreezeDays,
    required this.totalFrozenDays,
  });

  factory MePackageAssignment.fromJson(Map<String, dynamic> json) => MePackageAssignment(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        companyName: json['companyName'] as String?,
        branchId: json['branchId'] as int?,
        packageId: json['packageId'] as int,
        packageName: json['packageName'] as String?,
        category: json['category'] as String?,
        price: (json['price'] as num).toDouble(),
        status: json['status'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        sessionCount: json['sessionCount'] as int?,
        remainingSessions: json['remainingSessions'] as int?,
        maxFreezeDays: json['maxFreezeDays'] as int?,
        totalFrozenDays: json['totalFrozenDays'] as int? ?? 0,
      );

  final int id;
  final int companyId;
  final String? companyName;
  final int? branchId;
  final int packageId;
  final String? packageName;
  // Backend'in ham enum ismi ("GroupClass"/"MartialArts") - null ise bu paket
  // hiçbir grup dersi/kapasiteli ders için uygun değil (ör. 1:1 PT paketi).
  // Ders programı ekranı "Katıl" butonunun etkinliğini buna göre belirler.
  final String? category;
  final double price;
  // Backend'in ham enum ismi ("Active"/"Frozen") - Cancelled olanlar zaten
  // GetMeQueryHandler tarafından filtrelenir, bu yüzden burada asla görünmez.
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final int? sessionCount;
  final int? remainingSessions;
  // null = dondurma süresi sınırsız - üye kendi paketini dondururken ne
  // kadar hakkı kaldığını görebilsin diye (bkz. GymAppApi'nin
  // Package.MaxFreezeDays'i).
  final int? maxFreezeDays;
  final int totalFrozenDays;

  bool get isFrozen => status == 'Frozen';

  // null = sınırsız. Sınır varsa, bugüne kadar kullanılanı düşerek kalan
  // dondurma hakkını (gün) döner.
  int? get remainingFreezeDays => maxFreezeDays == null ? null : (maxFreezeDays! - totalFrozenDays).clamp(0, maxFreezeDays!);
}

class MeResult {
  const MeResult({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.preferredLanguage,
    required this.isAccountFrozen,
    required this.assignments,
    required this.packageAssignments,
  });

  factory MeResult.fromJson(Map<String, dynamic> json) => MeResult(
        id: json['id'] as int,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        preferredLanguage: json['preferredLanguage'] as String,
        isAccountFrozen: json['isAccountFrozen'] as bool,
        assignments: (json['assignments'] as List)
            .map((e) => MeAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
        packageAssignments: (json['packageAssignments'] as List)
            .map((e) => MePackageAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final int id;
  final String fullName;
  final String phone;
  final String? email;
  final String preferredLanguage;
  final bool isAccountFrozen;
  final List<MeAssignment> assignments;
  final List<MePackageAssignment> packageAssignments;

  // Gym üyeliği Assignment ile değil, sadece [packageAssignments] ile ifade
  // edilir (ana senaryo §3.2) - Assignment yalnızca personel yetkileri içindir.

  bool get isSuperAdmin => assignments.any((a) => a.role == 'SuperAdmin');

  // Bir Trainer'ın kendi programını görebileceği drawer girişini göstermek
  // için (bkz. TrainerScheduleScreen, GET /api/reservations/mine).
  bool get isTrainer => assignments.any((a) => a.role == 'Trainer');

  // Bu kullanıcının personel yönetmesine izin veren tek Assignment (varsa) - bir
  // GymAdmin şirketinin her şubesini denetler (kendi atamasında branchId null'dur);
  // bir BranchManager ise tam olarak tek bir şubeyle sınırlıdır. Sıradan bir
  // Member/Trainer için ve herhangi bir yerde AYRICA personel olmayan bir
  // SuperAdmin için null döner (SuperAdmin bunun yerine "Yeni Firma Ekle"
  // kullanır, bkz. AppDrawer).
  MeAssignment? get staffAssignment {
    for (final assignment in assignments) {
      if (assignment.role == 'GymAdmin' || assignment.role == 'BranchManager') {
        return assignment;
      }
    }
    return null;
  }

  // Aynı [staffAssignment] mantığının çoklu-şirket farkındalıklı sürümü -
  // GymAdmin/BranchManager olduğu HER şirketi döner (sadece ilkini değil).
  // AppDrawer'ın "Aktif Şirket" seçicisini doldurmak için kullanılır.
  List<MeAssignment> get staffAssignments =>
      assignments.where((a) => a.role == 'GymAdmin' || a.role == 'BranchManager').toList();

  // [staffAssignments] içinden [companyId]'ye eşleşen olanı döner - backend
  // artık X-Active-Company-Id header'ını (bkz.
  // core/providers/active_staff_company_provider.dart) çağıranın gerçekten
  // sahip olduğu bir şirketle eşleştiği sürece onurlandırıyor, bu yüzden bir
  // ekranın hangi şirket için işlem yaptığını göstermesi de aynı seçimi
  // yansıtmalı. companyId null'sa (henüz seçim yapılmadı) [staffAssignment]
  // (ilk eşleşme) döner. Eşleşme bulunamazsa ise null döner - ilk atamaya
  // düşmek, kullanıcının farkında olmadan yanlış gym bağlamında işlem
  // yapmasına yol açabilir.
  //
  // Varsayım: aynı firmada bir kullanıcı hem GymAdmin hem BranchManager
  // olamaz (backend bunu engelliyor). Yine de birden fazla eşleşme gelirse
  // ucuz bir savunma olarak daha geniş yetkili GymAdmin seçilir.
  MeAssignment? staffAssignmentFor(int? companyId) {
    if (companyId == null) return staffAssignment;
    MeAssignment? match;
    for (final assignment in staffAssignments) {
      if (assignment.companyId != companyId) continue;
      if (assignment.role == 'GymAdmin') return assignment;
      match ??= assignment;
    }
    return match;
  }
}
