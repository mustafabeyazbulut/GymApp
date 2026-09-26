import 'me_result.dart';

/// Kullanıcının AKTİF firmadaki rolüne göre hangi personel ekranlarını
/// görebileceği ve hangi işlemleri yapabileceği - menü (AppDrawer) ve
/// ekranlar aynı yetki matrisini buradan okur (ana senaryo §4.4-§4.6).
///
/// Yetkiler gym'e özeldir: bir firmada GymAdmin olmak, başka bir firmada
/// BranchManager olarak açılan menüleri etkilemez. Sistem Sahibi (SuperAdmin)
/// gym'lerin günlük işlerini yapmaz - bir firmada ayrıca personel ataması
/// yoksa sadece firma yönetimini görür.
///
/// Backend her istekte yetkiyi yeniden kontrol eder; bu sınıf yalnızca
/// arayüzün kullanıcıya yapamayacağı işlemleri göstermemesini sağlar.
class StaffPermissions {
  const StaffPermissions._({required this.activeAssignment, required this.isSuperAdmin});

  factory StaffPermissions.of(MeResult? me, int? activeCompanyId) => StaffPermissions._(
        activeAssignment: me?.staffAssignmentFor(activeCompanyId),
        isSuperAdmin: me?.isSuperAdmin ?? false,
      );

  /// Aktif firmadaki GymAdmin/BranchManager ataması - yoksa null.
  final MeAssignment? activeAssignment;
  final bool isSuperAdmin;

  bool get isGymAdmin => activeAssignment?.role == 'GymAdmin';
  bool get isBranchManager => activeAssignment?.role == 'BranchManager';
  bool get hasActiveStaffRole => activeAssignment != null;

  bool get canManageCompanies => isSuperAdmin;

  bool get canViewBranches => hasActiveStaffRole;
  // Şube açma/düzenleme/kapatma sadece GymAdmin'e açık; BranchManager kendi
  // şubesini salt-okunur görür.
  bool get canManageBranches => isGymAdmin;

  bool get canManageStaff => hasActiveStaffRole;
  bool get canAssignBranchManager => isGymAdmin;

  bool get canManagePackages => hasActiveStaffRole;
  bool get canCreateClassSession => hasActiveStaffRole;
  bool get canManageDoorAccess => isGymAdmin;
  bool get canViewGymReports => hasActiveStaffRole;
  bool get canUploadContent => hasActiveStaffRole;

  /// GymAdmin firmasının her şubesini görür; BranchManager sadece atandığı
  /// şubeyi. Backend şube filtresine ek bir savunma katmanıdır.
  bool canSeeBranch(int branchId) {
    if (isGymAdmin) return true;
    if (isBranchManager) return activeAssignment!.branchId == branchId;
    return false;
  }
}
