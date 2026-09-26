import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/providers/active_staff_assignment_provider.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/content_library/presentation/screens/upload_content_item_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MemoryStore implements ActiveAssignmentStore {
  @override
  Future<int?> read() async => null;

  @override
  Future<void> write(int? assignmentId) async {}
}

final _l10n = lookupAppLocalizations(const Locale('tr'));

Future<void> _pump(WidgetTester tester, List<MeAssignment> assignments) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final authRepository = _MockAuthRepository();
  when(() => authRepository.getMe()).thenAnswer((_) async => MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: assignments,
        packageAssignments: const [],
      ));
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWithValue(authRepository),
    activeAssignmentStoreProvider.overrideWithValue(_MemoryStore()),
  ]);
  addTearDown(container.dispose);
  container.listen(currentUserProvider, (_, _) {});
  await container.read(currentUserProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const UploadContentItemScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sistem Sahibi görevinde şube seçimi yerine genel içerik bilgisi gösterilir', (tester) async {
    await _pump(tester, const [
      MeAssignment(id: 1, companyId: null, companyName: null, branchId: null, role: 'SuperAdmin'),
    ]);

    expect(find.text(_l10n.contentLibraryUploadPlatformInfo), findsOneWidget);
    expect(find.text(_l10n.addStaffMemberBranchLabel), findsNothing);
  });

  testWidgets('BranchManager görevinde şube kilitli, genel içerik bilgisi yok', (tester) async {
    await _pump(tester, const [
      MeAssignment(id: 2, companyId: 1, companyName: 'Test Gym', branchId: 9, branchName: 'Kadıköy', role: 'BranchManager'),
    ]);

    expect(find.widgetWithText(TextFormField, 'Kadıköy'), findsOneWidget);
    expect(find.text(_l10n.contentLibraryUploadPlatformInfo), findsNothing);
  });
}
