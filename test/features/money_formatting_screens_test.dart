import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/package_management/data/real_package_repository.dart';
import 'package:gym_app/features/package_management/domain/package_repository.dart';
import 'package:gym_app/features/package_management/domain/package_summary.dart';
import 'package:gym_app/features/package_management/presentation/screens/package_management_screen.dart';
import 'package:gym_app/features/reports/data/real_reports_repository.dart';
import 'package:gym_app/features/reports/domain/reports_repository.dart';
import 'package:gym_app/features/reports/domain/revenue_report.dart';
import 'package:gym_app/features/reports/presentation/screens/revenue_report_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockPackageRepository extends Mock implements PackageRepository {}

class _MockReportsRepository extends Mock implements ReportsRepository {}

Future<void> _pump(WidgetTester tester, Widget screen, Locale locale, List<Override> overrides) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<Override> _packageOverrides() {
  final repository = _MockPackageRepository();
  when(() => repository.getPackages()).thenAnswer((_) async => const [
        PackageSummary(
          id: 1,
          companyId: 1,
          branchId: 9,
          name: 'Aylık',
          description: null,
          type: 'Duration',
          durationDays: 30,
          sessionCount: null,
          price: 1234.5,
          isActive: true,
          maxFreezeDays: null,
        ),
      ]);
  return [packageRepositoryProvider.overrideWithValue(repository)];
}

List<Override> _revenueOverrides() {
  final repository = _MockReportsRepository();
  when(() => repository.getRevenueReport(fromDate: any(named: 'fromDate'), toDate: any(named: 'toDate')))
      .thenAnswer((_) async => RevenueReport(
            fromDate: DateTime(2026, 9, 1),
            toDate: DateTime(2026, 9, 30),
            totalAmount: 31500.5,
            methodBreakdown: const [],
            dailyBreakdown: const [],
          ));
  return [reportsRepositoryProvider.overrideWithValue(repository)];
}

void main() {
  // Tutarlar sabit tr_TR yerine uygulamanın diline göre ve formatMoney'in
  // kuruşlu varsayılanıyla biçimlenir.
  group('Paket Yönetimi fiyatı', () {
    testWidgets('Türkçede ₺1.234,50', (tester) async {
      await _pump(tester, const PackageManagementScreen(), const Locale('tr'), _packageOverrides());
      expect(find.text('₺1.234,50'), findsOneWidget);
    });

    testWidgets('İngilizcede ₺1,234.50', (tester) async {
      await _pump(tester, const PackageManagementScreen(), const Locale('en'), _packageOverrides());
      expect(find.text('₺1,234.50'), findsOneWidget);
    });
  });

  group('Gelir raporu toplamı', () {
    testWidgets('Türkçede ₺31.500,50', (tester) async {
      await _pump(tester, const RevenueReportScreen(), const Locale('tr'), _revenueOverrides());
      expect(find.text('₺31.500,50'), findsOneWidget);
    });

    testWidgets('İngilizcede ₺31,500.50', (tester) async {
      await _pump(tester, const RevenueReportScreen(), const Locale('en'), _revenueOverrides());
      expect(find.text('₺31,500.50'), findsOneWidget);
    });
  });
}
