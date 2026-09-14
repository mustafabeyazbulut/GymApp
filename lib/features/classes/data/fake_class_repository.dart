import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/class_repository.dart';
import '../domain/class_session.dart';

part 'fake_class_repository.g.dart';

class FakeClassRepository implements ClassRepository {
  List<ClassSession> _sessions = const [
    ClassSession(
      id: 1,
      name: 'BJJ Temel',
      category: ClassCategory.bjj,
      timeRange: '19:00–20:30',
      trainerName: 'Mert Demir',
      capacity: 12,
      enrolledCount: 8,
    ),
    ClassSession(
      id: 2,
      name: 'Fitness Grup',
      category: ClassCategory.fitness,
      timeRange: '18:00–19:00',
      trainerName: 'Selin Kaya',
      capacity: 16,
      enrolledCount: 10,
    ),
    ClassSession(
      id: 3,
      name: 'Çocuk BJJ',
      category: ClassCategory.bjj,
      timeRange: '17:00–18:00',
      trainerName: 'Emre Yılmaz',
      capacity: 12,
      enrolledCount: 12,
    ),
  ];

  @override
  Future<List<ClassSession>> getClassSessions() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_sessions);
  }

  @override
  Future<void> reserveSpot(int classId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _sessions.indexWhere((s) => s.id == classId);
    final session = _sessions[index];
    if (session.isFull || session.isReservedByMe) {
      throw StateError('Class $classId cannot be reserved (full or already reserved).');
    }
    final updated = [..._sessions];
    updated[index] = session.copyWith(
      enrolledCount: session.enrolledCount + 1,
      isReservedByMe: true,
    );
    _sessions = updated;
  }
}

@riverpod
ClassRepository classRepository(Ref ref) => FakeClassRepository();
