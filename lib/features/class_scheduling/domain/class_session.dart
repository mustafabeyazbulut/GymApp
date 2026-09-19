enum ClassSessionCategory { groupClass, martialArts }

ClassSessionCategory classSessionCategoryFromApi(String value) => switch (value) {
      'MartialArts' => ClassSessionCategory.martialArts,
      _ => ClassSessionCategory.groupClass,
    };

String classSessionCategoryToApi(ClassSessionCategory category) => switch (category) {
      ClassSessionCategory.groupClass => 'GroupClass',
      ClassSessionCategory.martialArts => 'MartialArts',
    };

// Kapasiteli grup dersi (GymAppApi'nin ClassSession'ı) - mevcut 1:1
// Reservation/Trainer randevu sisteminden (features/classes) BAĞIMSIZ, ayrı
// bir modül.
class ClassSession {
  const ClassSession({
    required this.id,
    required this.branchId,
    required this.trainerUserId,
    required this.category,
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.enrolledCount,
    required this.cancellationCutoffHours,
  });

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
        id: json['id'] as int,
        branchId: json['branchId'] as int,
        trainerUserId: json['trainerUserId'] as int,
        category: classSessionCategoryFromApi(json['category'] as String),
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        capacity: json['capacity'] as int,
        enrolledCount: json['enrolledCount'] as int,
        cancellationCutoffHours: json['cancellationCutoffHours'] as int,
      );

  final int id;
  final int branchId;
  final int trainerUserId;
  final ClassSessionCategory category;
  final String name;
  final DateTime date;
  // Backend'in TimeOnly'si "HH:mm:ss" string olarak geliyor - basit
  // gösterim dışında bir işlem gerekmediği için ham string olarak tutuluyor.
  final String startTime;
  final String endTime;
  final int capacity;
  final int enrolledCount;
  final int cancellationCutoffHours;

  bool get isFull => enrolledCount >= capacity;

  // "HH:mm:ss" -> "HH:mm".
  String get startTimeLabel => startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
  String get endTimeLabel => endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
}
