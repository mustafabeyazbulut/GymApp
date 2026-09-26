import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/content_library/data/real_content_library_repository.dart';
import 'package:gym_app/features/content_library/domain/content_item.dart';
import 'package:gym_app/features/content_library/domain/content_library_repository.dart';
import 'package:gym_app/features/content_library/presentation/screens/content_library_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockContentLibraryRepository extends Mock implements ContentLibraryRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

final _l10n = lookupAppLocalizations(const Locale('tr'));

MePackageAssignment _package({String status = 'Active'}) => MePackageAssignment(
      id: 1,
      companyId: 1,
      companyName: 'Test Gym',
      branchId: 9,
      packageId: 5,
      packageName: 'Aylık',
      category: null,
      price: 1000,
      status: status,
      startDate: DateTime(2026, 1, 1),
      endDate: null,
      sessionCount: null,
      remainingSessions: null,
      maxFreezeDays: null,
      totalFrozenDays: 0,
    );

ContentItem _item(int id, String title, ContentSource source) => ContentItem(
      id: id,
      source: source,
      companyId: source == ContentSource.gym ? 1 : null,
      branchId: null,
      title: title,
      description: null,
      requiredAccessTier: 'Standard',
      mediaFileId: id,
      mediaContentType: 'video/mp4',
      isActive: true,
      createdAt: DateTime.utc(2026, 9, 20),
      hasAccess: true,
    );

Future<void> _pump(
  WidgetTester tester, {
  List<MeAssignment> assignments = const [],
  List<MePackageAssignment> packages = const [],
  List<ContentItem> items = const [],
}) async {
  final authRepository = _MockAuthRepository();
  when(() => authRepository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: assignments,
        packageAssignments: packages,
      ));
  final contentRepository = _MockContentLibraryRepository();
  when(() => contentRepository.getContentItems()).thenAnswer((_) async => items);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        contentLibraryRepositoryProvider.overrideWithValue(contentRepository),
        activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ContentLibraryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openGymTab(WidgetTester tester) async {
  await tester.tap(find.text(_l10n.contentLibraryTabGym));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('paketsiz üye varsayılan Genel sekmesinde platform içeriğini görür', (tester) async {
    await _pump(tester, items: [_item(1, 'Isınma rutini', ContentSource.platform)]);

    expect(find.text(_l10n.contentLibraryTabPlatform), findsOneWidget);
    expect(find.text('Isınma rutini'), findsOneWidget);
  });

  testWidgets('Genel sekmesi gym içeriğini, Salonum sekmesi platform içeriğini göstermez', (tester) async {
    await _pump(
      tester,
      packages: [_package()],
      items: [_item(1, 'Isınma rutini', ContentSource.platform), _item(2, 'Squat tekniği', ContentSource.gym)],
    );

    expect(find.text('Isınma rutini'), findsOneWidget);
    expect(find.text('Squat tekniği'), findsNothing);

    await _openGymTab(tester);

    expect(find.text('Squat tekniği'), findsOneWidget);
    expect(find.text('Isınma rutini'), findsNothing);
  });

  testWidgets('Genel içerik yoksa genel boş mesajı', (tester) async {
    await _pump(tester);

    expect(find.text(_l10n.contentLibraryPlatformEmptyMessage), findsOneWidget);
  });

  testWidgets('paketsiz üye Salonum sekmesinde "Paketin yok" görür', (tester) async {
    await _pump(tester, items: [_item(1, 'Isınma rutini', ContentSource.platform)]);
    await _openGymTab(tester);

    expect(find.text(_l10n.packageStatusNoPackageTitle), findsOneWidget);
    expect(find.text(_l10n.contentLibraryEmptyMessage), findsNothing);
  });

  testWidgets('paketi geçersiz üye Salonum sekmesinde nedeni görür', (tester) async {
    await _pump(tester, packages: [_package(status: 'Frozen')]);
    await _openGymTab(tester);

    expect(find.text(_l10n.packageStatusInvalidTitle), findsOneWidget);
    expect(find.text(_l10n.packageStatusInvalidFrozen), findsOneWidget);
  });

  testWidgets('geçerli paketli üye boş Salonum sekmesinde "Henüz içerik yok" görür', (tester) async {
    await _pump(tester, packages: [_package()]);
    await _openGymTab(tester);

    expect(find.text(_l10n.contentLibraryEmptyMessage), findsOneWidget);
    expect(find.text(_l10n.packageStatusNoPackageTitle), findsNothing);
  });

  // Personel paket üzerinden değil görevi üzerinden görüyor.
  testWidgets('paketi olmayan personel boş Salonum sekmesinde "Henüz içerik yok" görür', (tester) async {
    await _pump(
      tester,
      assignments: const [MeAssignment(id: 3, companyId: 1, companyName: 'Test Gym', branchId: 9, role: 'BranchManager')],
    );
    await _openGymTab(tester);

    expect(find.text(_l10n.contentLibraryEmptyMessage), findsOneWidget);
    expect(find.text(_l10n.packageStatusNoPackageTitle), findsNothing);
  });
}
