import 'class_session.dart';

enum ClassEnrollmentStatus { reserved, attended, cancelled, noShow }

ClassEnrollmentStatus classEnrollmentStatusFromApi(String value) => switch (value) {
      'Attended' => ClassEnrollmentStatus.attended,
      'Cancelled' => ClassEnrollmentStatus.cancelled,
      'NoShow' => ClassEnrollmentStatus.noShow,
      _ => ClassEnrollmentStatus.reserved,
    };

class MyClassEnrollment {
  const MyClassEnrollment({
    required this.id,
    required this.classSessionId,
    required this.className,
    required this.category,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory MyClassEnrollment.fromJson(Map<String, dynamic> json) => MyClassEnrollment(
        id: json['id'] as int,
        classSessionId: json['classSessionId'] as int,
        className: json['className'] as String,
        category: classSessionCategoryFromApi(json['category'] as String),
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        status: classEnrollmentStatusFromApi(json['status'] as String),
      );

  final int id;
  final int classSessionId;
  final String className;
  final ClassSessionCategory category;
  final DateTime date;
  final String startTime;
  final String endTime;
  final ClassEnrollmentStatus status;
}
