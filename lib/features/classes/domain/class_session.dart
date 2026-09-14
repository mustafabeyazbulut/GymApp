enum ClassCategory { bjj, fitness }

class ClassSession {
  const ClassSession({
    required this.id,
    required this.name,
    required this.category,
    required this.timeRange,
    required this.trainerName,
    required this.capacity,
    required this.enrolledCount,
    this.isReservedByMe = false,
  });

  final int id;
  final String name;
  final ClassCategory category;
  final String timeRange;
  final String trainerName;
  final int capacity;
  final int enrolledCount;
  final bool isReservedByMe;

  bool get isFull => enrolledCount >= capacity;

  ClassSession copyWith({int? enrolledCount, bool? isReservedByMe}) {
    return ClassSession(
      id: id,
      name: name,
      category: category,
      timeRange: timeRange,
      trainerName: trainerName,
      capacity: capacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isReservedByMe: isReservedByMe ?? this.isReservedByMe,
    );
  }
}
