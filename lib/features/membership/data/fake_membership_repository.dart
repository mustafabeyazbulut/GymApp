import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/membership_repository.dart';
import '../domain/membership_summary.dart';

part 'fake_membership_repository.g.dart';

class FakeMembershipRepository implements MembershipRepository {
  MembershipSummary _summary = const MembershipSummary(
    packageName: 'BJJ + Fitness Aylık',
    status: MembershipStatus.active,
    startDate: '01.09.2026',
    endDate: '30.09.2026',
    price: '₺2.500',
    isPaid: true,
    paymentHistory: [
      PaymentHistoryEntry(date: '01.09.2026', amount: '₺2.500'),
      PaymentHistoryEntry(date: '01.08.2026', amount: '₺2.500'),
      PaymentHistoryEntry(date: '01.07.2026', amount: '₺2.500'),
    ],
  );

  @override
  Future<MembershipSummary> getMembership() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _summary;
  }

  @override
  Future<void> requestFreeze() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _summary = _summary.copyWith(status: MembershipStatus.frozen);
  }
}

@riverpod
MembershipRepository membershipRepository(Ref ref) => FakeMembershipRepository();
