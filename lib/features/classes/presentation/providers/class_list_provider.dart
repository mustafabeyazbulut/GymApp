import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_class_repository.dart';
import '../../domain/class_session.dart';

part 'class_list_provider.g.dart';

@riverpod
class ClassList extends _$ClassList {
  @override
  Future<List<ClassSession>> build() {
    return ref.watch(classRepositoryProvider).getClassSessions();
  }

  Future<void> reserveSpot(int classId) async {
    final repository = ref.read(classRepositoryProvider);
    await repository.reserveSpot(classId);
    state = await AsyncValue.guard(repository.getClassSessions);
  }
}
