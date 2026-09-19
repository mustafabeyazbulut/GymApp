import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/class_scheduling/domain/class_enrollment.dart';
import 'package:gym_app/features/class_scheduling/domain/class_session.dart';

void main() {
  test('fromJson parses all fields and maps the status', () {
    final enrollment = MyClassEnrollment.fromJson({
      'id': 7,
      'classSessionId': 1,
      'className': 'Yoga',
      'category': 'GroupClass',
      'date': '2026-09-21',
      'startTime': '09:00:00',
      'endTime': '10:00:00',
      'status': 'Reserved',
    });

    expect(enrollment.id, 7);
    expect(enrollment.className, 'Yoga');
    expect(enrollment.category, ClassSessionCategory.groupClass);
    expect(enrollment.status, ClassEnrollmentStatus.reserved);
  });

  test('classEnrollmentStatusFromApi maps every known status string', () {
    expect(classEnrollmentStatusFromApi('Reserved'), ClassEnrollmentStatus.reserved);
    expect(classEnrollmentStatusFromApi('Attended'), ClassEnrollmentStatus.attended);
    expect(classEnrollmentStatusFromApi('Cancelled'), ClassEnrollmentStatus.cancelled);
    expect(classEnrollmentStatusFromApi('NoShow'), ClassEnrollmentStatus.noShow);
  });
}
