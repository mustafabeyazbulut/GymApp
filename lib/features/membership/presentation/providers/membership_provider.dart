import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../data/real_membership_repository.dart';
import '../../domain/membership_summary.dart';

part 'membership_provider.g.dart';

@riverpod
Future<List<PaymentHistoryEntry>> membershipPayments(Ref ref, int packageAssignmentId) =>
    ref.watch(membershipRepositoryProvider).getPayments(packageAssignmentId);

// Kendi state'i yok, sadece dondurma/açma aksiyonlarını sunuyor - her ikisi
// de backend'de PackageAssignment.Status'ü değiştiriyor, bu yüzden başarı
// sonrası currentUserProvider'ı invalidate ediyor ki membershipsProvider
// (ve ondan türeyen her şey - Home/Classes/Progress dahil) GetMe'den taze
// veriyle otomatik yeniden hesaplansın.
@riverpod
class MembershipActions extends _$MembershipActions {
  @override
  void build() {}

  Future<void> requestFreeze(int packageAssignmentId) async {
    await ref.read(membershipRepositoryProvider).requestFreeze(packageAssignmentId);
    ref.invalidate(currentUserProvider);
  }

  Future<void> requestUnfreeze(int packageAssignmentId) async {
    await ref.read(membershipRepositoryProvider).requestUnfreeze(packageAssignmentId);
    ref.invalidate(currentUserProvider);
  }
}
