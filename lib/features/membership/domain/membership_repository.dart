import 'membership_summary.dart';

// Not: freeze/unfreeze/cancel bilerek burada yok - backend'de
// FreezePackageAssignmentCommand vb. sadece [Authorize(Policy =
// "StaffManagement")] (bkz. GymAppApi PackageAssignmentsController), bir
// Member kendi üyeliğini kendi kendine dondurma/iptal etme yetkisine sahip
// değil. Ekran bunun yerine [membershipStaffContactNote] gösterir.
//
// Not: burada bir getMemberships() yok - çağıranın PackageAssignment
// listesi zaten GET /api/auth/me üzerinden currentUserProvider tarafından
// çekiliyor (bkz. membership_provider.dart'taki membershipsProvider); ikinci
// bir ağ çağrısıyla aynı veriyi tekrar çekmek yerine o tek kaynağı yeniden
// kullanıyoruz.
abstract interface class MembershipRepository {
  Future<List<PaymentHistoryEntry>> getPayments(int packageAssignmentId);
}
