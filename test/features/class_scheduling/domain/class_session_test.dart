import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/class_scheduling/domain/class_session.dart';

void main() {
  test('fromJson parses all fields and maps the category', () {
    final session = ClassSession.fromJson({
      'id': 1,
      'branchId': 10,
      'trainerUserId': 99,
      'category': 'MartialArts',
      'name': 'Karate',
      'date': '2026-09-21',
      'startTime': '18:00:00',
      'endTime': '19:00:00',
      'capacity': 12,
      'enrolledCount': 12,
      'cancellationCutoffHours': 4,
    });

    expect(session.id, 1);
    expect(session.category, ClassSessionCategory.martialArts);
    expect(session.startTimeLabel, '18:00');
    expect(session.endTimeLabel, '19:00');
    expect(session.isFull, isTrue);
  });

  test('classSessionCategoryFromApi falls back to groupClass for an unknown value', () {
    expect(classSessionCategoryFromApi('GroupClass'), ClassSessionCategory.groupClass);
    expect(classSessionCategoryFromApi('Unknown'), ClassSessionCategory.groupClass);
  });

  test('classSessionCategoryToApi round-trips both known categories', () {
    expect(classSessionCategoryToApi(ClassSessionCategory.groupClass), 'GroupClass');
    expect(classSessionCategoryToApi(ClassSessionCategory.martialArts), 'MartialArts');
  });
}
