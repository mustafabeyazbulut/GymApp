import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:gym_app/core/network/api_exception.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:gym_app/features/invitations/data/real_invitation_repository.dart';
import 'package:gym_app/features/invitations/domain/invitation.dart';
import 'package:gym_app/features/invitations/domain/invitation_repository.dart';
import 'package:gym_app/features/invitations/presentation/providers/invitations_provider.dart';
import 'package:gym_app/features/invitations/presentation/screens/invitations_screen.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockInvitationRepository extends Mock implements InvitationRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

final _l10n = lookupAppLocalizations(const Locale('tr'));

final _staff = Invitation(
  id: 7,
  type: InvitationType.staff,
  companyName: 'Test Gym',
  branchName: 'Kadıköy',
  role: 'Trainer',
  packageName: null,
  invitedByName: 'Yönetici Kadıköy',
  createdAt: DateTime.utc(2026, 9, 26, 10),
  expiresAt: DateTime.utc(2026, 9, 27, 15, 30),
);

final _package = Invitation(
  id: 8,
  type: InvitationType.package,
  companyName: 'Test Gym',
  branchName: 'Beşiktaş',
  role: null,
  packageName: 'Aylık Fitness',
  invitedByName: null,
  createdAt: DateTime.utc(2026, 9, 26, 11),
  expiresAt: DateTime.utc(2026, 9, 28, 6),
);

class _Harness {
  _Harness(this.repository, this.authRepository, this.container);

  final _MockInvitationRepository repository;
  final _MockAuthRepository authRepository;
  final ProviderContainer container;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required Future<List<Invitation>> Function() load,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repository = _MockInvitationRepository();
  when(() => repository.getMyInvitations()).thenAnswer((_) => load());
  when(() => repository.accept(any())).thenAnswer((_) async {});
  when(() => repository.reject(any())).thenAnswer((_) async {});
  final authRepository = _MockAuthRepository();
  when(() => authRepository.getMe()).thenAnswer((_) async => const MeResult(
        id: 1,
        fullName: 'Test User',
        phone: '+905551112233',
        email: null,
        preferredLanguage: 'tr',
        isAccountFrozen: false,
        assignments: [],
        packageAssignments: [],
      ));

  final container = ProviderContainer(overrides: [
    invitationRepositoryProvider.overrideWithValue(repository),
    authRepositoryProvider.overrideWithValue(authRepository),
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
        home: const InvitationsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(repository, authRepository, container);
}

void main() {
  setUpAll(() => registerFallbackValue(_staff));

  testWidgets('davetleri firma, şube, rol/paket, davet eden ve son geçerlilikle listeler', (tester) async {
    await _pump(tester, load: () async => [_staff, _package]);

    expect(find.text(_l10n.invitationsTypeStaff), findsOneWidget);
    expect(find.text(_l10n.invitationsTypePackage), findsOneWidget);
    expect(find.text('Test Gym'), findsNWidgets(2));
    expect(find.text('Kadıköy · ${_l10n.staffManagementRoleTrainer}'), findsOneWidget);
    expect(find.text('Beşiktaş · Aylık Fitness'), findsOneWidget);
    expect(find.text(_l10n.invitationsInvitedBy('Yönetici Kadıköy')), findsOneWidget);
    // Sunucu UTC gönderir, ekran yerel saatle gösterir.
    final expectedExpiry = DateFormat('dd.MM.yyyy HH:mm').format(_staff.expiresAt.toLocal());
    expect(find.text(_l10n.invitationsExpiresAt(expectedExpiry)), findsOneWidget);
    expect(find.text(_l10n.invitationsAcceptButton), findsNWidgets(2));
    expect(find.text(_l10n.invitationsRejectButton), findsNWidgets(2));
    // SMS kodu kullananlar için ikincil yol.
    expect(find.text(_l10n.invitationsConfirmWithCode), findsOneWidget);
  });

  testWidgets('GymAdmin davetinde şube yerine "Firma geneli" yazar', (tester) async {
    final gymAdmin = Invitation(
      id: 9,
      type: InvitationType.gymAdmin,
      companyName: 'Diğer Gym',
      branchName: null,
      role: 'GymAdmin',
      packageName: null,
      invitedByName: 'Sistem Sahibi',
      createdAt: DateTime.utc(2026, 9, 26),
      expiresAt: DateTime.utc(2026, 9, 27, 9),
    );
    await _pump(tester, load: () async => [gymAdmin]);

    expect(find.text(_l10n.invitationsTypeGymAdmin), findsOneWidget);
    expect(
      find.text('${_l10n.drawerActiveTaskCompanyWide} · ${_l10n.staffManagementRoleGymAdmin}'),
      findsOneWidget,
    );
  });

  testWidgets('ilk açılışta liste bir kez yüklenir', (tester) async {
    final harness = await _pump(tester, load: () async => [_staff]);

    verify(() => harness.repository.getMyInvitations()).called(1);
  });

  // Liste menü rozeti için (üst çubuk) önceden yüklenmiş olsa bile ekran
  // açılışında tazelenir.
  testWidgets('liste önceden yüklenmişse ekrana girilince yeniden yüklenir', (tester) async {
    final repository = _MockInvitationRepository();
    when(() => repository.getMyInvitations()).thenAnswer((_) async => [_staff]);
    final container = ProviderContainer(overrides: [invitationRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    container.listen(myInvitationsProvider, (_, _) {});
    await container.read(myInvitationsProvider.future);
    verify(() => repository.getMyInvitations()).called(1);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InvitationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => repository.getMyInvitations()).called(1);
    expect(find.text(_l10n.invitationsTypeStaff), findsOneWidget);
  });

  testWidgets('Onayla: daveti onaylar, kullanıcıyı ve listeyi yeniler', (tester) async {
    var remaining = [_staff, _package];
    final harness = await _pump(tester, load: () async => remaining);
    when(() => harness.repository.accept(any())).thenAnswer((_) async => remaining = [_package]);

    await tester.tap(find.text(_l10n.invitationsAcceptButton).first);
    await tester.pumpAndSettle();

    verify(() => harness.repository.accept(_staff)).called(1);
    // Yeni görev/paket hemen görünsün diye /me yeniden çekilir.
    verify(() => harness.authRepository.getMe()).called(2);
    expect(find.text(_l10n.invitationsAcceptedMessage), findsOneWidget);
    expect(find.text(_l10n.invitationsTypeStaff), findsNothing);
    expect(find.text(_l10n.invitationsTypePackage), findsOneWidget);
  });

  testWidgets('Reddet: onay diyaloğundan sonra reddeder', (tester) async {
    var remaining = [_staff];
    final harness = await _pump(tester, load: () async => remaining);
    when(() => harness.repository.reject(any())).thenAnswer((_) async => remaining = []);

    await tester.tap(find.text(_l10n.invitationsRejectButton));
    await tester.pumpAndSettle();
    expect(find.text(_l10n.invitationsRejectConfirmTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, _l10n.invitationsRejectButton));
    await tester.pumpAndSettle();

    verify(() => harness.repository.reject(_staff)).called(1);
    expect(find.text(_l10n.invitationsRejectedMessage), findsOneWidget);
    expect(find.text(_l10n.invitationsEmptyMessage), findsOneWidget);
  });

  testWidgets('Reddet diyaloğunda vazgeçilirse reddetmez', (tester) async {
    final harness = await _pump(tester, load: () async => [_staff]);

    await tester.tap(find.text(_l10n.invitationsRejectButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.accountDeletionCancelButton));
    await tester.pumpAndSettle();

    verifyNever(() => harness.repository.reject(any()));
    expect(find.text(_l10n.invitationsTypeStaff), findsOneWidget);
  });

  testWidgets('süresi dolmuş davet onaylanırken backend mesajı gösterilir ve liste tazelenir', (tester) async {
    var remaining = [_staff];
    final harness = await _pump(tester, load: () async => remaining);
    when(() => harness.repository.accept(any())).thenAnswer((_) async {
      remaining = [];
      throw const ApiException(statusCode: 410, errors: ['Davetin süresi dolmuş.']);
    });

    await tester.tap(find.text(_l10n.invitationsAcceptButton));
    await tester.pumpAndSettle();

    expect(find.text('Davetin süresi dolmuş.'), findsOneWidget);
    expect(find.text(_l10n.invitationsEmptyMessage), findsOneWidget);
  });

  testWidgets('bekleyen davet yoksa boş durum gösterir', (tester) async {
    await _pump(tester, load: () async => const []);

    expect(find.text(_l10n.invitationsEmptyMessage), findsOneWidget);
    expect(find.text(_l10n.invitationsConfirmWithCode), findsOneWidget);
  });

  testWidgets('yükleme hatasında mesaj ve yeniden dene gösterir', (tester) async {
    var fail = true;
    await _pump(tester, load: () async {
      if (fail) throw const ApiException(statusCode: 500, errors: ['Sunucu hatası']);
      return [_staff];
    });

    expect(find.text('Sunucu hatası'), findsOneWidget);
    fail = false;
    await tester.tap(find.text(_l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text(_l10n.invitationsTypeStaff), findsOneWidget);
  });
}
