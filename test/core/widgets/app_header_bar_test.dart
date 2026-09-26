import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/widgets/app_header_bar.dart';
import 'package:gym_app/features/invitations/data/real_invitation_repository.dart';
import 'package:gym_app/features/invitations/domain/invitation.dart';
import 'package:gym_app/features/invitations/domain/invitation_repository.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockInvitationRepository extends Mock implements InvitationRepository {}

Future<_MockInvitationRepository> _pump(WidgetTester tester, List<Invitation> invitations) async {
  final repository = _MockInvitationRepository();
  when(() => repository.getMyInvitations()).thenAnswer((_) async => invitations);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        invitationRepositoryProvider.overrideWithValue(repository),
        hasUnreadNotificationsProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(appBar: AppHeaderBar(title: 'Ana Sayfa')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  // Push/polling yok: shell'in üst çubuğu uygulama açılışında davetleri çeker
  // ve bekleyen davet varsa menü butonunda işlevsel bir nokta gösterir.
  testWidgets('açılışta davetleri çeker, bekleyen davet varsa menü noktası görünür', (tester) async {
    final repository = await _pump(tester, [
      Invitation(
        id: 1,
        type: InvitationType.staff,
        companyName: 'Test Gym',
        branchName: 'Kadıköy',
        role: 'Trainer',
        packageName: null,
        invitedByName: null,
        createdAt: DateTime.utc(2026, 9, 26),
        expiresAt: DateTime.utc(2026, 9, 27),
      ),
    ]);

    verify(() => repository.getMyInvitations()).called(1);
    expect(find.byKey(const ValueKey('appHeaderMenuDot')), findsOneWidget);
  });

  testWidgets('bekleyen davet yoksa menü noktası görünmez', (tester) async {
    await _pump(tester, const []);

    expect(find.byKey(const ValueKey('appHeaderMenuDot')), findsNothing);
  });
}
