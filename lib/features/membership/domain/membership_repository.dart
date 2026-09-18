import 'membership_summary.dart';

// Not: cancel (kalıcı iptal) bilerek burada yok - backend'de
// CancelPackageAssignmentCommand hâlâ sadece StaffManagement policy'siyle
// korunuyor (bkz. GymAppApi PackageAssignmentsController) - dondurma/açmanın
// aksine iptal geri alınamaz olduğu için üyenin kendi kendine yapabileceği
// bir işlem değil.
//
// Not: burada bir getMemberships() yok - çağıranın PackageAssignment
// listesi zaten GET /api/auth/me üzerinden currentUserProvider tarafından
// çekiliyor (bkz. membership_provider.dart'taki membershipsProvider); ikinci
// bir ağ çağrısıyla aynı veriyi tekrar çekmek yerine o tek kaynağı yeniden
// kullanıyoruz.
abstract interface class MembershipRepository {
  Future<List<PaymentHistoryEntry>> getPayments(int packageAssignmentId);

  Future<void> requestFreeze(int packageAssignmentId);
  Future<void> requestUnfreeze(int packageAssignmentId);

  // Çağıranın kendi telefonuna gelen bir paket daveti kodunu onaylar
  // (POST /api/package-assignments/confirm) - onay sonrası PackageAssignment
  // gerçekten var olur.
  Future<void> confirmPackageAssignment(String code);
}
