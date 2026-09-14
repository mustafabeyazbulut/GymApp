import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_membership_repository.dart';
import '../../domain/membership_summary.dart';

part 'membership_provider.g.dart';

@riverpod
class Membership extends _$Membership {
  @override
  Future<MembershipSummary> build() {
    return ref.watch(membershipRepositoryProvider).getMembership();
  }

  Future<void> requestFreeze() async {
    final repository = ref.read(membershipRepositoryProvider);
    await repository.requestFreeze();
    state = await AsyncValue.guard(repository.getMembership);
  }
}
