import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/home/presentation/screens/home_screen.dart';
import 'package:gym_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:gym_app/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  // Gym üyeliği sadece paketle oluşur (ana senaryo §3.2) - paketsiz üyeye
  // gösterilen boş durum "paket" dilini kullanır.
  testWidgets('paketsiz üye Home\'da paket diliyle boş durumu görür', (tester) async {
    final repository = _MockAuthRepository();
    when(() => repository.getMe()).thenAnswer((_) async => const MeResult(
          id: 1,
          fullName: 'Test User',
          phone: '+905551112233',
          email: null,
          preferredLanguage: 'tr',
          isAccountFrozen: false,
          assignments: [],
          packageAssignments: [],
        ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          hasUnreadNotificationsProvider.overrideWith((ref) => false),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('tr'));
    expect(find.text(l10n.membershipEmptyStateTitle), findsOneWidget);
    expect(find.text(l10n.membershipEmptyStateBody), findsOneWidget);
    expect(l10n.membershipEmptyStateBody, contains('Bir salon sana paket tanımladığında'));
    expect(lookupAppLocalizations(const Locale('en')).membershipEmptyStateBody, contains('assigns you a package'));
  });
}
