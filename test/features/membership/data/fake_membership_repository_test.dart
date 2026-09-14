import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/data/fake_membership_repository.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';

void main() {
  test('getMembership returns the fixed active membership with payment history', () async {
    final repository = FakeMembershipRepository();

    final summary = await repository.getMembership();

    expect(summary.packageName, 'BJJ + Fitness Aylık');
    expect(summary.status, MembershipStatus.active);
    expect(summary.startDate, '01.09.2026');
    expect(summary.endDate, '30.09.2026');
    expect(summary.price, '₺2.500');
    expect(summary.isPaid, true);
    expect(summary.paymentHistory, hasLength(3));
    expect(summary.paymentHistory[0].date, '01.09.2026');
    expect(summary.paymentHistory[0].amount, '₺2.500');
    expect(summary.paymentHistory[1].date, '01.08.2026');
    expect(summary.paymentHistory[1].amount, '₺2.500');
    expect(summary.paymentHistory[2].date, '01.07.2026');
    expect(summary.paymentHistory[2].amount, '₺2.500');
  });

  test('requestFreeze flips the status to frozen and leaves other fields unchanged', () async {
    final repository = FakeMembershipRepository();

    await repository.requestFreeze();
    final summary = await repository.getMembership();

    expect(summary.status, MembershipStatus.frozen);
    expect(summary.packageName, 'BJJ + Fitness Aylık');
    expect(summary.paymentHistory, hasLength(3));
  });
}
