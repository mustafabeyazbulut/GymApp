import 'package_assignment_summary.dart';
import 'package_summary.dart';

// Personelin (aktif görevi GymAdmin/BranchManager, bkz. StaffPermissions) paket
// şablonları tanımlaması, bir paketi bir üyeye atayıp (davet-onay akışına
// girer, bkz. ConfirmInvitationScreen) ödeme kaydetmesi için.
abstract interface class PackageRepository {
  Future<List<PackageSummary>> getPackages();

  Future<void> createPackage({
    required int companyId,
    // Her paket bir şubeye aittir; firma geneli paket yoktur (ana senaryo Karar 5).
    required int branchId,
    required String name,
    String? description,
    required String type,
    int? durationDays,
    int? sessionCount,
    required double price,
    // null = dondurma süresi sınırsız - üye bu paketi toplamda bu kadar
    // günden fazla dondurup açamaz (bkz. GymAppApi'nin
    // FreezePackageAssignmentCommandHandler'ı).
    int? maxFreezeDays,
  });

  Future<void> setPackageActive({required int packageId, required bool isActive});

  // Üyeye hemen bir PackageAssignment oluşturmaz - sadece telefonuna bir
  // onay kodu gönderir (bkz. CreatePackageAssignmentCommand).
  Future<void> assignPackage({required int packageId, required String memberPhone});

  Future<List<PackageAssignmentSummary>> getPackageAssignments({String? memberPhone});

  // Kalıcı iptal - freeze/unfreeze'in aksine geri alınamaz, bu yüzden
  // (MembershipRepository'nin kasıtlı olarak dışarıda bıraktığı gibi)
  // sadece burada, personel tarafında var.
  Future<void> cancelPackageAssignment(int packageAssignmentId);

  // Üye kendi paketini MembershipRepository üzerinden dondurup açabiliyor
  // (bkz. o dosyanın kendi yorumu) - bunlar AYNI backend uç noktalarının
  // (POST /api/package-assignments/{id}/freeze|unfreeze) personel
  // tarafındaki karşılığı: bir üye telefonla arayıp "seyahatteyim,
  // üyeliğimi dondurun" dediğinde ama uygulamayı kullanmıyor/bilmiyorsa,
  // personelin bunu onun adına yapabilmesi için.
  Future<void> freezePackageAssignment(int packageAssignmentId);
  Future<void> unfreezePackageAssignment(int packageAssignmentId);

  // Rezervasyonsuz/yürüyerek gelen (walk-in) check-in - ön masa personeli
  // için, TrainerScheduleScreen'in rezervasyon bazlı check-in'inden farklı
  // (orada Trainer da yapabiliyor, burada sadece personel).
  Future<void> recordGeneralCheckIn(int packageAssignmentId);

  Future<void> recordPayment({
    required int packageAssignmentId,
    required double amount,
    required String method,
    String? note,
  });
}
