import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/classes/data/fake_class_repository.dart';

void main() {
  test('getClassSessions returns the fixed mock list with a full and a non-full session', () async {
    final repository = FakeClassRepository();

    final sessions = await repository.getClassSessions();

    expect(sessions, isNotEmpty);
    expect(sessions.any((s) => s.enrolledCount < s.capacity), isTrue);
    expect(sessions.any((s) => s.enrolledCount == s.capacity), isTrue);
  });

  test('reserveSpot increments enrolledCount and marks the session as reserved by me', () async {
    final repository = FakeClassRepository();
    final before = await repository.getClassSessions();
    final target = before.firstWhere((s) => s.enrolledCount < s.capacity);

    await repository.reserveSpot(target.id);
    final after = await repository.getClassSessions();
    final updated = after.firstWhere((s) => s.id == target.id);

    expect(updated.enrolledCount, target.enrolledCount + 1);
    expect(updated.isReservedByMe, isTrue);
  });

  test('reserveSpot throws StateError for an already-full session', () async {
    final repository = FakeClassRepository();
    final sessions = await repository.getClassSessions();
    final fullSession = sessions.firstWhere((s) => s.enrolledCount == s.capacity);

    expect(() => repository.reserveSpot(fullSession.id), throwsStateError);
  });
}
