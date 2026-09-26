import 'me_result.dart';

/// Kullanıcının AKTİF görevine (menüdeki "Aktif Görev" seçimi) göre hangi
/// personel ekranlarını görebileceği ve hangi işlemleri yapabileceği - menü
/// (AppDrawer), rota korumaları ve ekranlar aynı yetki matrisini buradan okur
/// (ana senaryo §4.3-§4.6).
///
/// Yetkiler göreve özeldir: rol ve şube seçili atamadan gelir; kullanıcının
/// başka bir görevdeki rolü (ör. başka firmada GymAdmin, aynı firmada
/// antrenör) etkili değildir. Sistem Sahibi (SuperAdmin) gym'lerin günlük
/// işlerini yapmaz - "Sistem Sahibi" görevi seçiliyken sadece firma yönetimi
/// açıktır; bir personel görevi seçtiğinde de o istek için Sistem Sahibi
/// yetkisi kalkar (backend ile aynı davranış).
///
/// Backend her istekte yetkiyi yeniden kontrol eder; bu sınıf yalnızca
/// arayüzün kullanıcıya yapamayacağı işlemleri göstermemesini sağlar.
class StaffPermissions {
  const StaffPermissions._({required this.activeAssignment});

  /// [selectedAssignmentId]: kullanıcının ham seçimi (bkz.
  /// activeStaffAssignmentProvider); geçersizse varsayılan kurala döner.
  factory StaffPermissions.of(MeResult? me, int? selectedAssignmentId) =>
      StaffPermissions._(activeAssignment: me?.activeAssignment(selectedAssignmentId));

  /// Çözümlenmiş aktif görev (Sistem Sahibi dahil) - hiç görevi yoksa null.
  final MeAssignment? activeAssignment;

  String? get _role => activeAssignment?.role;

  bool get isSuperAdmin => _role == 'SuperAdmin';
  bool get isGymAdmin => _role == 'GymAdmin';
  bool get isBranchManager => _role == 'BranchManager';
  bool get isTrainer => _role == 'Trainer';

  /// Aktif görev yönetim görevi mi (GymAdmin/BranchManager) - gym işlem
  /// menülerinin ortak koşulu.
  bool get hasManagementRole => isGymAdmin || isBranchManager;

  bool get canManageCompanies => isSuperAdmin;

  bool get canViewBranches => hasManagementRole;
  // Şube açma/düzenleme/kapatma sadece GymAdmin'e açık; BranchManager kendi
  // şubesini salt-okunur görür.
  bool get canManageBranches => isGymAdmin;

  bool get canManageStaff => hasManagementRole;
  bool get canAssignBranchManager => isGymAdmin;

  bool get canManagePackages => hasManagementRole;
  bool get canCreateClassSession => hasManagementRole;
  bool get canManageDoorAccess => isGymAdmin;
  bool get canViewGymReports => hasManagementRole;
  bool get canUploadContent => hasManagementRole;

  bool get canViewTrainerSchedule => isTrainer;

  /// Yönetim ekranlarında şube seçimi yerine kilitlenen şube: BranchManager'ın
  /// kendi şubesi. GymAdmin (firma geneli) için null - şubelerden birini seçer.
  int? get fixedBranchId => isBranchManager ? activeAssignment!.branchId : null;

  /// GymAdmin firmasının her şubesini görür; BranchManager ve Trainer sadece
  /// atandığı şubeyi. Backend şube filtresine ek bir savunma katmanıdır.
  bool canSeeBranch(int branchId) {
    if (isGymAdmin) return true;
    if (isBranchManager || isTrainer) return activeAssignment!.branchId == branchId;
    return false;
  }
}
