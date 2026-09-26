import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/platform_reports/data/real_platform_report_repository.dart';
import 'package:gym_app/features/platform_reports/domain/platform_report.dart';
import 'package:gym_app/features/platform_reports/domain/platform_report_repository.dart';
import 'package:gym_app/features/platform_reports/presentation/screens/platform_reports_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlatformReportRepository extends Mock implements PlatformReportRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

const _companyMetrics = ReportMetrics(
  branchCount: 2,
  activeMemberCount: 30,
  trainerCount: 4,
  staffCount: 3,
  packageSalesInPeriod: 15,
  revenueInPeriod: 22000,
);

PlatformReportSummary _summary({List<CompanyReportRow>? companies, List<UserGrowthPoint>? growth}) =>
    PlatformReportSummary(
      totalUsers: 120,
      newUsersInPeriod: 14,
      userGrowth: growth ??
          [
            UserGrowthPoint(date: DateTime(2026, 9, 24), newUsers: 3),
            UserGrowthPoint(date: DateTime(2026, 9, 25), newUsers: 5),
          ],
      companyCount: 3,
      activeCompanyCount: 2,
      branchCount: 5,
      activeMemberCount: 48,
      trainerCount: 7,
      staffCount: 6,
      packageSalesInPeriod: 21,
      revenueInPeriod: 31500.5,
      currency: 'TRY',
      companies: companies ??
          const [CompanyReportRow(companyId: 1, companyName: 'Test Gym', isActive: true, metrics: _companyMetrics)],
    );

Future<_MockPlatformReportRepository> _pump(
  WidgetTester tester, {
  Future<PlatformReportSummary> Function(ReportPeriod period)? load,
  Locale locale = const Locale('tr'),
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockPlatformReportRepository();
  when(() => repository.getSummary(any()))
      .thenAnswer((invocation) => (load ?? (_) async => _summary())(invocation.positionalArguments.single as ReportPeriod));
  when(() => repository.getCompanyBranches(any(), any())).thenAnswer((_) async => const [
        BranchReportRow(
          branchId: 9,
          branchName: 'Kadıköy',
          isActive: true,
          metrics: ReportMetrics(
            branchCount: null,
            activeMemberCount: 20,
            trainerCount: 3,
            staffCount: 1,
            packageSalesInPeriod: 10,
            revenueInPeriod: 15000.25,
          ),
        ),
      ]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [platformReportRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PlatformReportsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  setUpAll(() => registerFallbackValue(ReportPeriod.days30));

  testWidgets('özet kutucuklarını ve Türkçe biçimli geliri gösterir', (tester) async {
    await _pump(tester);

    expect(find.text(_l10n.platformReportsTotalUsers), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text(_l10n.platformReportsNewUsers(14)), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text('48'), findsOneWidget);
    expect(find.text('₺31.500,50'), findsOneWidget);
    expect(find.text(_l10n.platformReportsUserGrowth), findsOneWidget);
    // Ekran okuyucu grafiği anlamlı, yerelleştirilmiş bir özetle okur (3 + 5).
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(_l10n.platformReportsUserGrowthSemantics(8)))), findsOneWidget);
  });

  testWidgets('İngilizcede gelir ₺31,500.50 biçiminde', (tester) async {
    await _pump(tester, locale: const Locale('en'));

    expect(find.text('₺31,500.50'), findsOneWidget);
  });

  testWidgets('varsayılan dönem 30 gün; dönem değişince rapor yeniden yüklenir', (tester) async {
    final repository = await _pump(tester);
    verify(() => repository.getSummary(ReportPeriod.days30)).called(1);

    await tester.tap(find.text(_l10n.platformReportsPeriod90));
    await tester.pumpAndSettle();

    verify(() => repository.getSummary(ReportPeriod.days90)).called(1);
  });

  testWidgets('firma satırına dokununca şube kırılımı açılır', (tester) async {
    final repository = await _pump(tester);

    expect(find.text('Test Gym'), findsOneWidget);
    expect(find.text(_l10n.companyManagementActiveBadge), findsOneWidget);
    verifyNever(() => repository.getCompanyBranches(any(), any()));

    await tester.tap(find.text('Test Gym'));
    await tester.pumpAndSettle();

    verify(() => repository.getCompanyBranches(1, ReportPeriod.days30)).called(1);
    expect(find.text('Kadıköy'), findsOneWidget);
    expect(find.text(_l10n.platformReportsMetricsLine(20, 3, 1, 10)), findsOneWidget);
    expect(find.text('₺15.000,25'), findsOneWidget);
  });

  testWidgets('firma yoksa boş mesaj, büyüme yoksa grafik yerine mesaj', (tester) async {
    await _pump(tester, load: (_) async => _summary(companies: const [], growth: const []));

    expect(find.text(_l10n.platformReportsNoCompanies), findsOneWidget);
    expect(find.text(_l10n.platformReportsUserGrowthEmpty), findsOneWidget);
  });

  testWidgets('hata durumunda mesaj ve yeniden dene', (tester) async {
    var fail = true;
    await _pump(tester, load: (_) async {
      if (fail) throw const ApiException(statusCode: 500, errors: ['Rapor alınamadı']);
      return _summary();
    });

    expect(find.text('Rapor alınamadı'), findsOneWidget);
    fail = false;
    await tester.tap(find.text(_l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.platformReportsTotalUsers), findsOneWidget);
  });
}
