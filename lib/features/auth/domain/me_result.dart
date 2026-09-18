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
    required this.price,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.sessionCount,
    required this.remainingSessions,
  });

  factory MePackageAssignment.fromJson(Map<String, dynamic> json) => MePackageAssignment(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        companyName: json['companyName'] as String?,
        branchId: json['branchId'] as int?,
        packageId: json['packageId'] as int,
        packageName: json['packageName'] as String?,
        price: (json['price'] as num).toDouble(),
        status: json['status'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        sessionCount: json['sessionCount'] as int?,
        remainingSessions: json['remainingSessions'] as int?,
      );

  final int id;
  final int companyId;
  final String? companyName;
  final int? branchId;
  final int packageId;
  final String? packageName;
  final double price;
  // Backend'in ham enum ismi ("Active"/"Frozen") - Cancelled olanlar zaten
  // GetMeQueryHandler tarafından filtrelenir, bu yüzden burada asla görünmez.
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final int? sessionCount;
  final int? remainingSessions;

  bool get isFrozen => status == 'Frozen';
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

  // Sadece bir 'Member' ataması gerçek bir üyelik/paket anlamına gelir - bir
  // SuperAdmin/GymAdmin/BranchManager/Trainer ataması bunu ifade etmez, bu yüzden
  // bu roller sadece assignments.isNotEmpty diye üye tarafına özel Home/Classes/
  // Progress/Membership mock içeriğine düşmemelidir (bu düzeltilen bir hataydı:
  // gerçek bir üyeliği olmayan saf bir SuperAdmin dahil her giriş yapan kullanıcı
  // aynı sahte "Merhaba, Elnara" Home ekranına iniyordu).
  bool get hasActiveMembership => assignments.any((a) => a.role == 'Member');

  bool get isSuperAdmin => assignments.any((a) => a.role == 'SuperAdmin');

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
  // yansıtmalı. companyId null'sa veya eşleşme bulunamazsa [staffAssignment]
  // (ilk eşleşme) davranışına geri döner - backend'in kendi fallback'iyle
  // aynı.
  MeAssignment? staffAssignmentFor(int? companyId) {
    if (companyId == null) return staffAssignment;
    for (final assignment in staffAssignments) {
      if (assignment.companyId == companyId) return assignment;
    }
    return staffAssignment;
  }
}
