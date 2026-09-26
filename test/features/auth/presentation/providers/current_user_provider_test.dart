import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/auth/data/real_auth_repository.dart';
import 'package:gym_app/features/auth/domain/auth_repository.dart';
import 'package:gym_app/features/auth/domain/me_result.dart';
import 'package:gym_app/features/auth/presentation/providers/current_user_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('build() returns the repository MeResult', () async {
    final repository = _MockAuthRepository();
    when(() => repository.getMe()).thenAnswer((_) async => const MeResult(
          id: 1, fullName: 'Ayşe', phone: '+905551112233', email: null, preferredLanguage: 'tr',
          isAccountFrozen: false, assignments: [], packageAssignments: [],
        ));
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);

    final result = await container.read(currentUserProvider.future);

    expect(result.id, 1);
    expect(result.fullName, 'Ayşe');
    expect(result.phone, '+905551112233');
    expect(result.email, isNull);
    expect(result.assignments, isEmpty);
  });
}
