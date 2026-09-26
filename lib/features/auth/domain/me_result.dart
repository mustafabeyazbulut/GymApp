class MeAssignment {
  const MeAssignment({
    this.id,
    required this.companyId,
    required this.companyName,
    required this.branchId,
    this.branchName,
    required this.role,
  });

  factory MeAssignment.fromJson(Map<String, dynamic> json) => MeAssignment(
        id: json['id'] as int?,
        companyId: json['companyId'] as int?,
        companyName: json['companyName'] as String?,
        branchId: json['branchId'] as int?,
        branchName: json['branchName'] as String?,
        role: json['role'] as String,
      );

  // Atamanın kendi Id'si - X-Active-Assignment-Id header'ının değeri. Eski
  // backend sürümleri göndermediği için null olabilir.
  final int? id;
  // Platform genelinde bir atama için null olur (ör. SuperAdmin); tek bir şirkete bağlı değildir.
  final int? companyId;
  final String? companyName;
  final int? branchId;
  // GymAdmin (firma geneli) atamasında ve eski backend sürümlerinde null.
  final String? branchName;
  final String role;

  /// Bir gym'deki personel görevi (GymAdmin, BranchManager, Trainer).
  bool get isStaffRole => role != 'SuperAdmin' && _contextRolePriority.containsKey(role);
}

// Aktif görev olarak seçilebilen roller ve varsayılan seçimdeki öncelikleri
// (küçük olan önce) - backend'in header'sız istekte uyguladığı kuralla aynı.
const _contextRolePriority = {'SuperAdmin': 0, 'GymAdmin': 1, 'BranchManager': 2, 'Trainer': 3};

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

  /// Kullanıcının gym'lerdeki tüm personel görevleri (GymAdmin, BranchManager,
  /// Trainer).
  List<MeAssignment> get staffAssignments => assignments.where((a) => a.isStaffRole).toList();

  /// Menüdeki "Aktif Görev" seçicisinin listelediği görevler: Sistem Sahibi
  /// (varsa, en üstte) + personel görevleri (backend'in döndüğü sırayla).
  /// Seçici bunlardan birden fazlası varsa görünür.
  List<MeAssignment> get selectableContexts => [
        ...assignments.where((a) => a.role == 'SuperAdmin'),
        ...staffAssignments,
      ];

  /// Kullanıcı henüz bir görev seçmediyse (veya seçimi geçersizleştiyse)
  /// kullanılacak görev: SuperAdmin > GymAdmin > BranchManager > Trainer; aynı
  /// rolde en küçük Id. Id'si gelmeyen atamalar (eski backend) sona düşer.
  MeAssignment? get defaultActiveAssignment {
    MeAssignment? best;
    for (final candidate in selectableContexts) {
      if (best == null || _comesBefore(candidate, best)) best = candidate;
    }
    return best;
  }

  /// [selectedAssignmentId] seçilebilir görevlerden biriyse onu, değilse
  /// (seçim yok, atama kaldırılmış, başka kullanıcıdan kalmış)
  /// [defaultActiveAssignment]'ı döner. Sonuç SuperAdmin ise kullanıcı Sistem
  /// Sahibi olarak hareket ediyordur (aktif görev header'ı gönderilmez).
  MeAssignment? activeAssignment(int? selectedAssignmentId) {
    if (selectedAssignmentId != null) {
      for (final assignment in selectableContexts) {
        if (assignment.id == selectedAssignmentId) return assignment;
      }
    }
    return defaultActiveAssignment;
  }

  static bool _comesBefore(MeAssignment a, MeAssignment b) {
    final byRole = _contextRolePriority[a.role]!.compareTo(_contextRolePriority[b.role]!);
    if (byRole != 0) return byRole < 0;
    if (a.id == null) return false;
    if (b.id == null) return true;
    return a.id! < b.id!;
  }
}
