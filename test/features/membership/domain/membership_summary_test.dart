import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';

final _now = DateTime(2026, 9, 26, 12);

MembershipSummary _membership({
  MembershipStatus status = MembershipStatus.active,
  DateTime? endDate,
  int? sessionCount,
  int? remainingSessions,
}) =>
    MembershipSummary(
      id: 1,
      companyName: 'Test Gym',
      packageName: 'Aylık',
      category: null,
      status: status,
      startDate: DateTime(2026, 9, 1),
      endDate: endDate,
      price: 1000,
      sessionCount: sessionCount,
      remainingSessions: remainingSessions,
      maxFreezeDays: null,
      remainingFreezeDays: null,
    );

void main() {
  // Backend'deki PackageAssignmentValidity ile aynı kural:
  // Active && (EndDate null || > şimdi) && (RemainingSessions null || > 0).
  group('validityAt', () {
    test('aktif, bitişi gelecekte ve hakkı olan paket geçerli', () {
      final membership = _membership(endDate: _now.add(const Duration(days: 1)), sessionCount: 10, remainingSessions: 3);
      expect(membership.validityAt(_now), PackageValidity.valid);
    });

    test('bitiş tarihi ve seans sınırı olmayan aktif paket geçerli', () {
      expect(_membership().validityAt(_now), PackageValidity.valid);
    });

    test('donmuş paket geçersiz', () {
      expect(_membership(status: MembershipStatus.frozen).validityAt(_now), PackageValidity.frozen);
    });

    test('bitiş tarihi geçmiş paket geçersiz', () {
      expect(_membership(endDate: _now.subtract(const Duration(minutes: 1))).validityAt(_now), PackageValidity.expired);
    });

    test('bitiş tarihi tam şimdi olan paket geçersiz (şimdiden sonra olmalı)', () {
      expect(_membership(endDate: _now).validityAt(_now), PackageValidity.expired);
    });

    test('kalan seansı sıfır olan paket geçersiz', () {
      expect(_membership(sessionCount: 10, remainingSessions: 0).validityAt(_now), PackageValidity.noSessionsLeft);
    });

    test('donmuşluk süre ve seanstan önce raporlanır', () {
      final membership = _membership(
        status: MembershipStatus.frozen,
        endDate: _now.subtract(const Duration(days: 1)),
        remainingSessions: 0,
      );
      expect(membership.validityAt(_now), PackageValidity.frozen);
    });
  });

  group('membershipAvailabilityAt', () {
    test('hiç paket yoksa none', () {
      expect(membershipAvailabilityAt(const [], _now).state, MembershipAvailabilityState.none);
    });

    test('en az bir geçerli paket varsa valid', () {
      final result = membershipAvailabilityAt(
        [_membership(status: MembershipStatus.frozen), _membership()],
        _now,
      );
      expect(result.state, MembershipAvailabilityState.valid);
    });

    test('hiçbiri geçerli değilse invalid ve ilk paketin nedeni', () {
      final result = membershipAvailabilityAt(
        [_membership(sessionCount: 5, remainingSessions: 0), _membership(status: MembershipStatus.frozen)],
        _now,
      );
      expect(result.state, MembershipAvailabilityState.invalid);
      expect(result.reason, PackageValidity.noSessionsLeft);
    });

    test('seçili paket varsa neden ondan alınır', () {
      final frozen = MembershipSummary(
        id: 2,
        companyName: 'Test Gym',
        packageName: 'PT',
        category: null,
        status: MembershipStatus.frozen,
        startDate: DateTime(2026, 9, 1),
        endDate: null,
        price: 1000,
        sessionCount: null,
        remainingSessions: null,
        maxFreezeDays: null,
        remainingFreezeDays: null,
      );
      final result = membershipAvailabilityAt(
        [_membership(sessionCount: 5, remainingSessions: 0), frozen],
        _now,
        selectedId: 2,
      );
      expect(result.reason, PackageValidity.frozen);
    });
  });
}
