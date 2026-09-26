import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/package_status_empty_state.dart';
import 'package:gym_app/features/membership/domain/membership_summary.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pump(WidgetTester tester, MembershipAvailability availability) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PackageStatusEmptyState(availability: availability)),
      ),
    );

void main() {
  testWidgets('paketi olmayan üyeye "Paketin yok" ve açıklama gösterir', (tester) async {
    await _pump(tester, const MembershipAvailability(MembershipAvailabilityState.none));

    expect(find.text(_l10n.packageStatusNoPackageTitle), findsOneWidget);
    expect(find.text(_l10n.packageStatusNoPackageBody), findsOneWidget);
  });

  final reasons = {
    PackageValidity.frozen: _l10n.packageStatusInvalidFrozen,
    PackageValidity.expired: _l10n.packageStatusInvalidExpired,
    PackageValidity.noSessionsLeft: _l10n.packageStatusInvalidNoSessions,
  };
  for (final entry in reasons.entries) {
    testWidgets('geçersiz paket (${entry.key.name}) için "Paketin geçerli değil" ve neden gösterir', (tester) async {
      await _pump(tester, MembershipAvailability(MembershipAvailabilityState.invalid, entry.key));

      expect(find.text(_l10n.packageStatusInvalidTitle), findsOneWidget);
      expect(find.text(entry.value), findsOneWidget);
    });
  }
}
