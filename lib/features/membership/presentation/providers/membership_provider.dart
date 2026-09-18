import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/real_membership_repository.dart';
import '../../domain/membership_summary.dart';

part 'membership_provider.g.dart';

// Çağıranın SAHİP OLDUĞU her PackageAssignment - GET /api/auth/me üzerinden
// zaten uygulama genelinde tek kaynak olan currentUserProvider'dan türetilir,
// ayrı bir ağ çağrısı yapmaz. Şirket/paket bazında birden fazla olabilir
// (bkz. GymAppApi'nin project-member-package-linkage-design.md roadmap'i).
@riverpod
Future<List<MembershipSummary>> memberships(Ref ref) async {
  final me = await ref.watch(currentUserProvider.future);
  return me.packageAssignments
      .map((assignment) => MembershipSummary(
            id: assignment.id,
            companyName: assignment.companyName ?? '',
            packageName: assignment.packageName ?? '',
            status: membershipStatusFromApi(assignment.status),
            startDate: assignment.startDate,
            endDate: assignment.endDate,
            price: assignment.price,
            sessionCount: assignment.sessionCount,
            remainingSessions: assignment.remainingSessions,
          ))
      .toList();
}

// Kullanıcının context switcher'da seçtiği PackageAssignment id'si - null
// olduğu sürece MembershipScreen listedeki ilkini gösterir.
@riverpod
class SelectedMembershipId extends _$SelectedMembershipId {
  @override
  int? build() => null;

  void select(int id) => state = id;
}

@riverpod
Future<List<PaymentHistoryEntry>> membershipPayments(Ref ref, int packageAssignmentId) =>
    ref.watch(membershipRepositoryProvider).getPayments(packageAssignmentId);
