import 'membership_summary.dart';

abstract interface class MembershipRepository {
  Future<MembershipSummary> getMembership();
  Future<void> requestFreeze();
}
