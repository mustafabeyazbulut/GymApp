import 'class_session.dart';

abstract interface class ClassRepository {
  Future<List<ClassSession>> getClassSessions();
  Future<void> reserveSpot(int classId);
}
